library(shiny)
library(cooccur)
library(DT)

# ---- helper: build filtered cograph object ----
.filtered_cograph <- function(result, min_w) {
  r <- result[result$weight >= min_w, ]
  if (nrow(r) == 0L) return(NULL)
  # Null stored matrices so as_cograph rebuilds from the filtered edge rows
  attr(r, "matrix")     <- NULL
  attr(r, "raw_matrix") <- NULL
  tryCatch(as_cograph(r), error = function(e) NULL)
}


# ---- UI ----

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-size: 14px; }
    .sidebar-panel { background: #f8f9fa; padding: 15px; border-radius: 6px; }
    .section-header { font-weight: 600; margin-top: 14px; margin-bottom: 4px;
                      color: #333; border-bottom: 1px solid #dee2e6; padding-bottom: 3px; }
    .btn-primary  { background-color: #2c7be5; border-color: #2c7be5; }
    .btn-run      { margin-top: 6px; margin-bottom: 10px; }
    .export-strip { margin-top: 18px; padding: 12px; background: #f0f4fb;
                    border-radius: 6px; border: 1px solid #d0dff5; }
    .export-strip h5 { margin-top: 0; margin-bottom: 10px; color: #2c7be5; }
    html, body { height: 100%; }
    body { display: flex; flex-direction: column; min-height: 100vh; }
    .container-fluid { flex: 1; }
    .app-footer {
      padding: 12px 24px; margin-top: 30px;
      border-top: 1px solid #e4e8ee;
      font-size: 11px; color: #adb5bd;
      text-align: center; line-height: 2;
      background: #fff;
    }
    .app-footer a { color: #adb5bd; text-decoration: none; border-bottom: 1px dotted #ced4da; }
    .app-footer a:hover { color: #495057; border-bottom-color: #495057; }
    .app-footer .sep { margin: 0 8px; color: #dee2e6; }
    .app-footer .block { display: block; margin-top: 2px; }
  "))),

  titlePanel("cooccur — Co-occurrence Network Explorer"),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      class = "sidebar-panel",

      # ---- Data ----
      div(class = "section-header", "Data"),
      radioButtons("data_source", label = NULL,
                   choices = c("Upload CSV"        = "upload",
                               "Built-in: movies"  = "movies",
                               "Built-in: actors"  = "actors"),
                   selected = "upload"),

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

      # ---- BUILD NETWORK (early) ----
      actionButton("run", "Build network", class = "btn-primary btn-run",
                   width = "100%", icon = icon("play")),

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
        column(6, numericInput("min_occur", "Min freq",  value = 1, min = 1, step = 1)),
        column(6, numericInput("threshold", "Threshold", value = 0, min = 0, step = 0.01))
      ),
      numericInput("top_n", "Top N edges (0 = all)", value = 0, min = 0, step = 25),

      # ---- Scale ----
      div(class = "section-header", "Scale (optional)"),
      selectInput("scale", label = NULL,
                  choices = c("none", "minmax", "log", "log10",
                              "binary", "zscore", "sqrt", "proportion"),
                  selected = "none")
    ),

    mainPanel(
      width = 9,
      tabsetPanel(
        id = "tabs",

        # ---- Summary ----
        tabPanel("Summary",
          br(),
          verbatimTextOutput("summary_out"),
          br(),
          verbatimTextOutput("print_out"),

          # Early export strip
          uiOutput("export_strip")
        ),

        # ---- View edge table ----
        tabPanel("View edge table",
          br(),
          DTOutput("edge_table")
        ),

        # ---- Network (cograph) ----
        tabPanel("Network",
          br(),
          fluidRow(
            column(3,
              sliderInput("min_edge_w", "Min edge weight",
                          min = 0, max = 1, value = 0, step = 0.01,
                          width = "100%")
            ),
            column(3,
              selectInput("net_layout", "Layout",
                          choices = c("Fruchterman-Reingold" = "fr",
                                      "Kamada-Kawai"         = "kk",
                                      "Gephi"                = "gephi",
                                      "Circle"               = "circle",
                                      "Nicely"               = "nicely"),
                          selected = "fr", width = "100%")
            ),
            column(3,
              numericInput("label_size", "Label size", value = 0.8,
                           min = 0.3, max = 2, step = 0.1, width = "100%")
            ),
            column(3,
              numericInput("edge_width_max", "Max edge width", value = 4,
                           min = 0.5, max = 10, step = 0.5, width = "100%")
            )
          ),
          uiOutput("net_ui")
        ),

        # ---- Export ----
        tabPanel("Export",
          br(),
          h5("Edge list"),
          downloadButton("dl_csv2",     "CSV (default)"),
          " ",
          downloadButton("dl_gephi2",   "CSV (Gephi)"),
          br(), br(),
          h5("Network file"),
          downloadButton("dl_graphml2", "GraphML (igraph)")
        )
      )
    )
  ),

  tags$footer(class = "app-footer",
    tags$span(
      tags$a(href = "https://saqr.me",     target = "_blank", "Mohammed Saqr"),
      tags$span(class = "sep", "·"),
      tags$a(href = "https://sonsoles.me", target = "_blank", "Sonsoles López-Pernas")
    ),
    tags$span(class = "block",
      tags$a(href = "https://lamethods.org/book1/chapters/ch15-sna/ch15-sna.html",
             target = "_blank",
             "Social Network Analysis: A Primer, a Guide and a Tutorial in R"),
      tags$span(class = "sep", "·"),
      tags$a(href = "https://link.springer.com/chapter/10.1007/978-3-031-25336-2_5",
             target = "_blank",
             "Scientometrics: A Concise Introduction and a Detailed Methodology")
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

  # ---- pre-fill columns when source changes ----
  observeEvent(data_loaded(), {
    d        <- data_loaded()
    cols     <- colnames(d)
    cols_opt <- c("— none —" = "", cols)

    default_field <- if (input$data_source == "movies") "genres" else
                     if (input$data_source == "actors") "actor"  else cols[1]
    updateSelectInput(session, "field_sel",    choices = cols,     selected = default_field)

    default_sep <- if (input$data_source == "movies") "," else ""
    updateTextInput(session,   "sep_val",      value   = default_sep)

    default_by <- if (input$data_source == "actors") "tconst" else ""
    updateSelectInput(session, "by_sel",       choices = cols_opt, selected = default_by)

    updateSelectInput(session, "split_by_sel", choices = cols_opt, selected = "")
  })

  # ---- dynamic column selectors ----
  output$ui_field <- renderUI({
    d <- data_loaded()
    selectInput("field_sel", "Field (nodes)", choices = colnames(d))
  })

  output$ui_sep <- renderUI({
    textInput("sep_val", "Separator (sep)", value = "",
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

  # ---- reactive: cooccurrence result ----
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

  # update slider range to match result weights
  observeEvent(result(), {
    r <- result()
    if (!is.null(r) && nrow(r) > 0) {
      mn <- round(min(r$weight, na.rm = TRUE), 4)
      mx <- round(max(r$weight, na.rm = TRUE), 4)
      updateSliderInput(session, "min_edge_w",
                        min   = mn, max = mx, value = mn,
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

  output$export_strip <- renderUI({
    req(result())
    div(class = "export-strip",
      h5("Export"),
      downloadButton("dl_csv",     "CSV"),
      " ",
      downloadButton("dl_gephi",   "Gephi CSV"),
      " ",
      downloadButton("dl_graphml", "GraphML")
    )
  })

  # ---- View edge table tab ----
  output$edge_table <- renderDT({
    req(result())
    r <- as.data.frame(result())
    r$weight <- round(r$weight, 6)
    datatable(r,
              filter   = "top",
              rownames = FALSE,
              options  = list(pageLength = 25, scrollX = TRUE))
  })

  # ---- Network tab (cograph) ----
  output$net_ui <- renderUI({
    req(result())
    r   <- result()
    net <- .filtered_cograph(r, input$min_edge_w)

    if (is.null(net)) {
      tags$div(class = "alert alert-warning",
               "No edges above the current weight threshold.")
    } else if (net$n_edges > 3000) {
      tags$div(class = "alert alert-info",
               sprintf("%d edges — too many to render clearly. Raise the minimum weight filter.",
                       net$n_edges))
    } else {
      plotOutput("cograph_plot", height = "600px")
    }
  })

  output$cograph_plot <- renderPlot({
    req(result())
    if (!requireNamespace("cograph", quietly = TRUE)) {
      plot.new()
      text(0.5, 0.5, "Package 'cograph' is required for network plots.\ninstall.packages('cograph')",
           cex = 1.2, col = "firebrick")
      return(invisible(NULL))
    }
    r   <- result()
    net <- .filtered_cograph(r, input$min_edge_w)
    req(!is.null(net))

    cograph::splot(
      net,
      layout          = input$net_layout,
      scale_nodes_by  = "degree",
      label_size      = input$label_size,
      edge_width_range = c(0.1, input$edge_width_max)
    )
  })

  # ---- Download handlers (shared by Summary strip + Export tab) ----
  output$dl_csv <- downloadHandler(
    filename = function() paste0("cooccurrence_", Sys.Date(), ".csv"),
    content  = function(f) write.csv(as.data.frame(result()), f, row.names = FALSE)
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
      igraph::write_graph(as_igraph(result()), f, format = "graphml")
    }
  )

  # ---- Export tab handlers (separate IDs to avoid duplicate-ID conflict) ----
  output$dl_csv2 <- downloadHandler(
    filename = function() paste0("cooccurrence_", Sys.Date(), ".csv"),
    content  = function(f) write.csv(as.data.frame(result()), f, row.names = FALSE)
  )

  output$dl_gephi2 <- downloadHandler(
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

  output$dl_graphml2 <- downloadHandler(
    filename = function() paste0("cooccurrence_", Sys.Date(), ".graphml"),
    content  = function(f) {
      req(result())
      if (!requireNamespace("igraph", quietly = TRUE)) {
        showNotification("igraph is required for GraphML export.", type = "error")
        return(NULL)
      }
      igraph::write_graph(as_igraph(result()), f, format = "graphml")
    }
  )
}

shinyApp(ui, server)
