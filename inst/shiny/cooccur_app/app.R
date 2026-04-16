library(shiny)
library(cooccur)
library(DT)
library(visNetwork)

# ---- helpers ----

.looks_delimited <- function(data, field) {
  if (is.null(field) || !field %in% names(data)) return(FALSE)
  vals <- head(as.character(data[[field]]), 30)
  any(grepl("[,;|/]", vals, perl = TRUE))
}

.build_vis <- function(edges, min_w) {
  edges <- edges[edges$weight >= min_w, ]
  if (nrow(edges) == 0) return(NULL)
  if (nrow(edges) > 2000) return("too_many")

  nodes_vec <- unique(c(edges$from, edges$to))
  deg <- table(c(edges$from, edges$to))

  nodes <- data.frame(
    id    = nodes_vec,
    label = nodes_vec,
    value = as.integer(deg[nodes_vec]),
    title = paste0("<b>", nodes_vec, "</b><br>degree: ", as.integer(deg[nodes_vec])),
    stringsAsFactors = FALSE
  )

  vis_edges <- data.frame(
    from  = edges$from,
    to    = edges$to,
    value = edges$weight,
    title = sprintf("weight: %.4g<br>count: %d", edges$weight, edges$count),
    stringsAsFactors = FALSE
  )

  list(nodes = nodes, edges = vis_edges)
}


# ---- UI ----

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-size: 14px; }
    .sidebar-panel { background: #f8f9fa; padding: 15px; border-radius: 6px; }
    .section-header { font-weight: 600; margin-top: 14px; margin-bottom: 4px;
                      color: #333; border-bottom: 1px solid #dee2e6; padding-bottom: 3px; }
    .btn-primary { background-color: #2c7be5; border-color: #2c7be5; }
    #run { margin-top: 10px; }
  "))),

  titlePanel(
    tags$span(
      tags$img(src = NULL),
      "cooccur — Co-occurrence Network Explorer"
    )
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      class = "sidebar-panel",

      # ---- Data ----
      div(class = "section-header", "Data"),
      radioButtons("data_source", label = NULL,
                   choices = c("Built-in: movies" = "movies",
                               "Built-in: actors"  = "actors",
                               "Upload CSV"        = "upload"),
                   selected = "movies"),

      conditionalPanel(
        condition = "input.data_source == 'upload'",
        fileInput("file", NULL, accept = c(".csv", "text/csv"),
                  placeholder = "Choose CSV file")
      ),

      # ---- Columns ----
      div(class = "section-header", "Columns"),

      uiOutput("ui_field"),
      uiOutput("ui_sep"),
      uiOutput("ui_by"),
      uiOutput("ui_split_by"),

      # ---- Similarity & Counting ----
      div(class = "section-header", "Similarity"),
      selectInput("similarity", label = NULL,
                  choices = c("none", "jaccard", "cosine", "inclusion",
                              "association", "dice", "equivalence", "relative"),
                  selected = "jaccard"),

      div(class = "section-header", "Counting"),
      radioButtons("counting", label = NULL,
                   choices = c("full", "fractional"), selected = "full",
                   inline = TRUE),

      # ---- Filters ----
      div(class = "section-header", "Filters"),
      fluidRow(
        column(6, numericInput("min_occur",  "Min freq",  value = 1,  min = 1, step = 1)),
        column(6, numericInput("threshold",  "Threshold", value = 0,  min = 0, step = 0.01))
      ),
      numericInput("top_n", "Top N edges (0 = all)", value = 0, min = 0, step = 25),

      # ---- Scale (advanced) ----
      div(class = "section-header", "Scale (optional)"),
      selectInput("scale", label = NULL,
                  choices = c("none", "minmax", "log", "log10",
                              "binary", "zscore", "sqrt", "proportion"),
                  selected = "none"),

      actionButton("run", "Build network", class = "btn-primary",
                   width = "100%", icon = icon("play"))
    ),

    mainPanel(
      width = 9,
      tabsetPanel(
        id = "tabs",

        tabPanel("Summary",
                 br(),
                 verbatimTextOutput("summary_out"),
                 br(),
                 verbatimTextOutput("print_out")),

        tabPanel("Edge table",
                 br(),
                 DTOutput("edge_table")),

        tabPanel("Network",
                 br(),
                 fluidRow(
                   column(4,
                     sliderInput("min_edge_w", "Min edge weight",
                                 min = 0, max = 1, value = 0, step = 0.01,
                                 width = "100%")
                   ),
                   column(4,
                     selectInput("vis_layout", "Layout",
                                 choices = c("layout_with_fr"    = "layout_with_fr",
                                             "layout_with_kk"    = "layout_with_kk",
                                             "layout_nicely"     = "layout_nicely",
                                             "layout_in_circle"  = "layout_in_circle"),
                                 selected = "layout_with_fr", width = "100%")
                   )
                 ),
                 uiOutput("net_ui")),

        tabPanel("Export",
                 br(),
                 h5("Download edge list"),
                 downloadButton("dl_csv",     "CSV (default)"),
                 " ",
                 downloadButton("dl_gephi",   "CSV (Gephi)"),
                 br(), br(),
                 h5("Download network"),
                 downloadButton("dl_graphml", "GraphML (igraph)"))
      )
    )
  )
)


# ---- Server ----

server <- function(input, output, session) {

  # ---- reactive: loaded data ----
  data_loaded <- reactive({
    switch(input$data_source,
      movies = cooccur::movies,
      actors = cooccur::actors,
      upload = {
        req(input$file)
        read.csv(input$file$datapath, stringsAsFactors = FALSE)
      }
    )
  })

  # ---- pre-fill column selectors when built-in data changes ----
  observeEvent(data_loaded(), {
    d <- data_loaded()
    cols     <- colnames(d)
    cols_opt <- c("— none —" = "", cols)

    # field
    default_field <- if (input$data_source == "movies") "genres" else
                     if (input$data_source == "actors") "actor"  else cols[1]
    updateSelectInput(session, "field_sel",    choices = cols,     selected = default_field)

    # sep
    default_sep <- if (input$data_source == "movies") "," else ""
    updateTextInput(session,   "sep_val",      value   = default_sep)

    # by
    default_by <- if (input$data_source == "actors") "tconst" else ""
    updateSelectInput(session, "by_sel",       choices = cols_opt, selected = default_by)

    # split_by
    default_split <- if (input$data_source == "movies") "" else ""
    updateSelectInput(session, "split_by_sel", choices = cols_opt, selected = default_split)
  })

  # ---- dynamic column UI ----
  output$ui_field <- renderUI({
    d <- data_loaded()
    selectInput("field_sel", "Field (nodes)", choices = colnames(d))
  })

  output$ui_sep <- renderUI({
    textInput("sep_val", "Separator (sep)", value = ",",
              placeholder = "e.g.  ,  ;  |")
  })

  output$ui_by <- renderUI({
    d <- data_loaded()
    selectInput("by_sel", "Group by (by)",
                choices = c("— none —" = "", colnames(d)), selected = "")
  })

  output$ui_split_by <- renderUI({
    d <- data_loaded()
    selectInput("split_by_sel", "Split by",
                choices = c("— none —" = "", colnames(d)), selected = "")
  })

  # ---- reactive: run cooccurrence ----
  result <- eventReactive(input$run, {
    d        <- data_loaded()
    field    <- input$field_sel
    sep      <- if (nzchar(trimws(input$sep_val))) trimws(input$sep_val) else NULL
    by       <- if (nzchar(input$by_sel))       input$by_sel       else NULL
    split_by <- if (nzchar(input$split_by_sel)) input$split_by_sel else NULL
    top_n    <- if (input$top_n > 0) as.integer(input$top_n) else NULL
    scale    <- if (input$scale == "none") NULL else input$scale

    withProgress(message = "Computing co-occurrences…", value = 0.5, {
      tryCatch(
        cooccurrence(d,
                     field      = field,
                     sep        = sep,
                     by         = by,
                     split_by   = split_by,
                     similarity = input$similarity,
                     counting   = input$counting,
                     scale      = scale,
                     threshold  = input$threshold,
                     min_occur  = as.integer(input$min_occur),
                     top_n      = top_n),
        error = function(e) {
          showNotification(conditionMessage(e), type = "error", duration = 8)
          NULL
        }
      )
    })
  })

  # update slider range when result changes
  observeEvent(result(), {
    r <- result()
    if (!is.null(r) && nrow(r) > 0) {
      mn <- min(r$weight, na.rm = TRUE)
      mx <- max(r$weight, na.rm = TRUE)
      updateSliderInput(session, "min_edge_w",
                        min   = round(mn, 4),
                        max   = round(mx, 4),
                        value = round(mn, 4),
                        step  = round((mx - mn) / 100, 4))
    }
  })

  # ---- Summary tab ----
  output$summary_out <- renderPrint({
    req(result())
    summary(result())
  })

  output$print_out <- renderPrint({
    req(result())
    print(result(), n = 10L)
  })

  # ---- Edge table tab ----
  output$edge_table <- renderDT({
    req(result())
    r <- as.data.frame(result())
    num_cols <- intersect(c("weight"), names(r))
    r[num_cols] <- lapply(r[num_cols], round, digits = 6)
    datatable(r,
              filter    = "top",
              rownames  = FALSE,
              options   = list(pageLength = 25, scrollX = TRUE))
  })

  # ---- Network tab ----
  output$net_ui <- renderUI({
    req(result())
    r    <- result()
    vis  <- .build_vis(r, input$min_edge_w)

    if (is.null(vis)) {
      tags$div(class = "alert alert-warning",
               "No edges above the current weight threshold.")
    } else if (identical(vis, "too_many")) {
      tags$div(class = "alert alert-info",
               sprintf("Too many edges to render (> 2,000). Raise the minimum weight filter."))
    } else {
      visNetworkOutput("vis_plot", height = "580px")
    }
  })

  output$vis_plot <- renderVisNetwork({
    req(result())
    r   <- result()
    vis <- .build_vis(r, input$min_edge_w)
    req(is.list(vis) && !identical(vis, "too_many"))

    visNetwork(vis$nodes, vis$edges, width = "100%") |>
      visOptions(highlightNearest = list(enabled = TRUE, degree = 1),
                 nodesIdSelection = TRUE) |>
      visNodes(scaling = list(min = 10, max = 40),
               font   = list(size = 14)) |>
      visEdges(scaling = list(min = 1, max = 8),
               smooth  = list(enabled = TRUE, type = "continuous")) |>
      visIgraphLayout(layout = input$vis_layout) |>
      visInteraction(navigationButtons = TRUE) |>
      visPhysics(enabled = FALSE)
  })

  # ---- Export tab ----
  output$dl_csv <- downloadHandler(
    filename = function() paste0("cooccurrence_", Sys.Date(), ".csv"),
    content  = function(f) {
      write.csv(as.data.frame(result()), f, row.names = FALSE)
    }
  )

  output$dl_gephi <- downloadHandler(
    filename = function() paste0("cooccurrence_gephi_", Sys.Date(), ".csv"),
    content  = function(f) {
      req(result())
      gephi <- tryCatch(
        cooccurrence(data_loaded(),
                     field      = input$field_sel,
                     sep        = if (nzchar(trimws(input$sep_val))) trimws(input$sep_val) else NULL,
                     by         = if (nzchar(input$by_sel))       input$by_sel       else NULL,
                     split_by   = if (nzchar(input$split_by_sel)) input$split_by_sel else NULL,
                     similarity = input$similarity,
                     counting   = input$counting,
                     scale      = if (input$scale == "none") NULL else input$scale,
                     threshold  = input$threshold,
                     min_occur  = as.integer(input$min_occur),
                     top_n      = if (input$top_n > 0) as.integer(input$top_n) else NULL,
                     output     = "gephi"),
        error = function(e) NULL
      )
      write.csv(as.data.frame(gephi), f, row.names = FALSE)
    }
  )

  output$dl_graphml <- downloadHandler(
    filename = function() paste0("cooccurrence_", Sys.Date(), ".graphml"),
    content  = function(f) {
      req(result())
      if (!requireNamespace("igraph", quietly = TRUE)) {
        showNotification("igraph is required for GraphML export.", type = "error")
        return(NULL)
      }
      g <- as_igraph(result())
      igraph::write_graph(g, f, format = "graphml")
    }
  )
}

shinyApp(ui, server)
