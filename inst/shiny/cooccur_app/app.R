library(shiny)
library(cooccur)
library(DT)

# Allow uploads up to 100 MB (default is 5 MB).
# Note: if served behind nginx, also set `client_max_body_size 100m;`
# in the server block — otherwise nginx returns 413 before Shiny sees the request.
options(shiny.maxRequestSize = 100 * 1024^2)

data("movies", package = "cooccur", envir = environment())
data("actors", package = "cooccur", envir = environment())

# ---- helper: build filtered cograph object ----
# Returns a list(status, value, message). status is one of:
#   "ok"      — value is the cograph_network
#   "empty"   — no rows survived the weight filter
#   "error"   — as_cograph() failed; message has the reason
.filtered_cograph <- function(result, min_w) {
  r <- result[result$weight >= min_w, ]
  if (nrow(r) == 0L)
    return(list(status = "empty", value = NULL, message = NULL))
  # Null stored matrices so as_cograph rebuilds from the filtered edge rows
  attr(r, "matrix")     <- NULL
  attr(r, "raw_matrix") <- NULL
  tryCatch(
    list(status = "ok", value = as_cograph(r), message = NULL),
    error = function(e) list(status = "error", value = NULL,
                             message = conditionMessage(e))
  )
}


# ---- UI ----

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-size: 14px; }

    /* ── Title bar ── */
    .app-title {
      padding: 16px 24px 12px;
      background: linear-gradient(135deg, #1a56db 0%, #2c7be5 60%, #4facfe 100%);
      margin-bottom: 0;
    }
    .app-title-main {
      display: block;
      font-size: 28px; font-weight: 700; letter-spacing: -0.5px;
      color: #fff; font-family: 'Segoe UI', Helvetica, Arial, sans-serif;
    }
    .app-title-sub {
      display: block;
      font-size: 13px; font-weight: 400; letter-spacing: 0.5px;
      color: rgba(255,255,255,0.80); margin-top: 2px;
      font-family: 'Segoe UI', Helvetica, Arial, sans-serif;
    }

    /* ── Sidebar ── */
    .sidebar-panel { background: #f8f9fa; padding: 15px; border-radius: 6px; }
    .section-header { font-weight: 600; margin-top: 14px; margin-bottom: 4px;
                      color: #333; border-bottom: 1px solid #dee2e6; padding-bottom: 3px; }
    .btn-primary  { background-color: #2c7be5; border-color: #2c7be5; }
    .btn-run      { margin-top: 6px; margin-bottom: 10px; }
    .export-strip { margin-top: 18px; padding: 12px; background: #f0f4fb;
                    border-radius: 6px; border: 1px solid #d0dff5; }
    .export-strip h5 { margin-top: 0; margin-bottom: 10px; color: #2c7be5; }

    /* ── Help page ── */
    .help-section {
      background: #fff; border: 1px solid #e4e8ee; border-radius: 8px;
      padding: 20px 24px; margin-bottom: 18px;
    }
    .help-section h4 {
      color: #1a56db; font-weight: 700; margin-top: 0; margin-bottom: 10px;
      border-bottom: 2px solid #e8eff9; padding-bottom: 6px;
    }
    .help-section p, .help-section li { color: #444; line-height: 1.65; }
    .help-section code {
      background: #f0f4fb; color: #c7254e;
      padding: 1px 5px; border-radius: 3px; font-size: 92%;
    }
    .measure-table { width: 100%; border-collapse: collapse; font-size: 13px; }
    .measure-table th {
      background: #1a56db; color: #fff;
      padding: 7px 12px; text-align: left; font-weight: 600;
    }
    .measure-table td { padding: 6px 12px; border-bottom: 1px solid #eee; }
    .measure-table tr:last-child td { border-bottom: none; }
    .measure-table tr:nth-child(even) td { background: #f8f9ff; }
    .badge-fmt {
      display: inline-block; padding: 2px 8px; border-radius: 12px;
      font-size: 11px; font-weight: 600; margin-right: 4px;
      background: #e8eff9; color: #1a56db;
    }

    /* ── Footer ── */
    html, body { height: 100%; }
    body { display: flex; flex-direction: column; min-height: 100vh; }
    .container-fluid { flex: 1; }
    .app-footer {
      padding: 18px 24px 14px;
      margin-top: 30px;
      border-top: 2px solid #e4e8ee;
      text-align: center;
      background: #fafbfd;
    }
    .app-footer .footer-authors {
      font-size: 15px; font-weight: 600; color: #2c3e50;
      margin-bottom: 6px;
    }
    .app-footer .footer-authors a {
      color: #1a56db; text-decoration: none;
    }
    .app-footer .footer-authors a:hover { text-decoration: underline; }
    .app-footer .footer-authors .sep { margin: 0 10px; color: #adb5bd; font-weight: 400; }
    .app-footer .footer-refs {
      font-size: 11px; color: #adb5bd; line-height: 2;
    }
    .app-footer .footer-refs a {
      color: #adb5bd; text-decoration: none; border-bottom: 1px dotted #ced4da;
    }
    .app-footer .footer-refs a:hover { color: #495057; border-bottom-color: #495057; }
    .app-footer .footer-refs .sep { margin: 0 8px; color: #dee2e6; }
  "))),

  tags$div(class = "app-title",
    tags$span(class = "app-title-main", "cooccur"),
    tags$span(class = "app-title-sub", "Co-occurrence Network Explorer")
  ),

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
      uiOutput("ui_by"),
      uiOutput("ui_split_by"),
      uiOutput("ui_sep"),

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

        # ---- Help / About ----
        tabPanel(
          title = tagList(tags$span(style = "color:#1a56db;", "\u2139\ufe0f"), " Help"),
          value = "help",
          br(),

          fluidRow(
            column(8,

              div(class = "help-section",
                tags$h4("\U0001f9e0 What is co-occurrence analysis?"),
                tags$p(
                  "Co-occurrence analysis detects how often items appear together across ",
                  "transactions — documents, films, sessions, papers, or any grouping unit. ",
                  "The result is a weighted network whose nodes are items and whose edges ",
                  "reflect the strength of their co-appearance. This package supports ",
                  tags$strong("six input formats"), " and ", tags$strong("eight similarity measures"),
                  " so you can work with almost any tabular dataset without reshaping it first."
                )
              ),

              div(class = "help-section",
                tags$h4("\U0001f4c2 Input formats"),
                tags$p("The app auto-detects the format from your data shape. You can also guide it with the ", tags$code("sep"), " and ", tags$code("by"), " fields."),
                tags$table(class = "measure-table",
                  tags$thead(tags$tr(
                    tags$th("Format"), tags$th("Description"), tags$th("Example")
                  )),
                  tags$tbody(
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "delimited")),
                            tags$td("One cell holds multiple items separated by a delimiter"),
                            tags$td(tags$code("genres = \"Drama,Action\""))),
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "long")),
                            tags$td("Each row is one item; a second column groups them"),
                            tags$td(tags$code("actor + movie_id"))),
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "wide")),
                            tags$td("Each row is a transaction; multiple columns are items"),
                            tags$td("survey response columns")),
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "binary")),
                            tags$td("Wide matrix of 0/1 presence flags"),
                            tags$td("term-document matrix")),
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "list")),
                            tags$td("R list of character vectors (programmatic use)"),
                            tags$td("\u2014")),
                    tags$tr(tags$td(tags$span(class = "badge-fmt", "multi_delimited")),
                            tags$td("Multiple delimited columns to merge before counting"),
                            tags$td("keywords_1, keywords_2 columns"))
                  )
                )
              ),

              div(class = "help-section",
                tags$h4("\U0001f4cf Similarity measures"),
                tags$table(class = "measure-table",
                  tags$thead(tags$tr(
                    tags$th("Measure"), tags$th("Interpretation"), tags$th("Best for")
                  )),
                  tags$tbody(
                    tags$tr(tags$td(tags$strong("none")),    tags$td("Raw co-occurrence count"),          tags$td("Frequency-based analyses")),
                    tags$tr(tags$td(tags$strong("jaccard")), tags$td("Intersection / union"),             tags$td("General-purpose; unaffected by item frequency")),
                    tags$tr(tags$td(tags$strong("cosine")),  tags$td("Geometric similarity of profiles"), tags$td("Text / keyword networks")),
                    tags$tr(tags$td(tags$strong("inclusion")), tags$td("How much A contains B"),          tags$td("Hierarchical / subset relationships")),
                    tags$tr(tags$td(tags$strong("association")), tags$td("Lift above independence"),      tags$td("Market-basket / rule mining")),
                    tags$tr(tags$td(tags$strong("dice")),    tags$td("Harmonic Jaccard"),                 tags$td("Balanced co-occurrence")),
                    tags$tr(tags$td(tags$strong("equivalence")), tags$td("Bibliographic coupling style"), tags$td("Citation / reference networks")),
                    tags$tr(tags$td(tags$strong("relative")), tags$td("Normalized by total pairs"),       tags$td("Comparing across different-sized datasets"))
                  )
                )
              )
            ),

            column(4,

              div(class = "help-section",
                tags$h4("\u26a1 Quick start"),
                tags$ol(
                  tags$li("Choose ", tags$strong("Upload CSV"), " or a built-in dataset in the sidebar."),
                  tags$li("Select the ", tags$strong("Field"), " column that holds your items (e.g. genres, actors, keywords)."),
                  tags$li("If items are comma-separated inside one cell, set ", tags$strong("Separator"), " (e.g. ", tags$code(","), ")."),
                  tags$li("For long-format data (one item per row), pick the ", tags$strong("Group by"), " column that identifies each transaction."),
                  tags$li("Choose a ", tags$strong("Similarity"), " measure (Jaccard is a safe default)."),
                  tags$li("Click ", tags$strong("Build network"), "."),
                  tags$li("Explore results in the ", tags$strong("Summary"), ", ", tags$strong("View edge table"), ", and ", tags$strong("Network"), " tabs.")
                )
              ),

              div(class = "help-section",
                tags$h4("\u2699\ufe0f Key parameters"),
                tags$dl(
                  tags$dt(tags$code("split_by")),
                  tags$dd("Build a separate network per group (e.g. per year). Adds a ", tags$code("group"), " column to the edge table."),
                  tags$dt(tags$code("Min freq")),
                  tags$dd("Drop items that appear in fewer than this many transactions — removes noise."),
                  tags$dt(tags$code("Threshold")),
                  tags$dd("Drop edges below this similarity — keeps only strong connections."),
                  tags$dt(tags$code("Top N edges")),
                  tags$dd("Keep only the N strongest edges. Use with large datasets."),
                  tags$dt(tags$code("Scale")),
                  tags$dd("Optional post-normalization rescaling (min-max, log, z-score, …).")
                )
              ),

              div(class = "help-section",
                tags$h4("\U0001f4be Export formats"),
                tags$ul(
                  tags$li(tags$strong("CSV (default)"), " — standard edge list for R / Python."),
                  tags$li(tags$strong("CSV (Gephi)"), " — ", tags$code("Source / Target / Weight"), " columns for Gephi import."),
                  tags$li(tags$strong("GraphML"), " — interoperable XML graph format for Gephi, Cytoscape, NetworkX.")
                )
              )
            )
          )
        ),

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
    tags$div(class = "footer-authors",
      tags$a(href = "https://saqr.me",     target = "_blank", "Mohammed Saqr"),
      tags$span(class = "sep", "\u00b7"),
      tags$a(href = "https://sonsoles.me", target = "_blank", "Sonsoles L\u00f3pez-Pernas"),
      tags$span(class = "sep", "\u00b7"),
      tags$a(href = "https://kamilamisiejuk.com", target = "_blank", "Kamila Misiejuk")
    ),
    tags$div(class = "footer-refs",
      tags$a(href = "https://lamethods.org/book1/chapters/ch15-sna/ch15-sna.html",
             target = "_blank",
             "Social Network Analysis: A Primer, a Guide and a Tutorial in R"),
      tags$span(class = "sep", "\u00b7"),
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
      movies = movies,
      actors = actors,
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
      mn_raw <- min(r$weight, na.rm = TRUE)
      mx_raw <- max(r$weight, na.rm = TRUE)
      # Floor the slider min below the true minimum so the initial
      # filter (value >= min) includes every edge. Rounding up would
      # silently drop edges at the minimum weight.
      mn <- floor(mn_raw * 10000) / 10000
      mx <- ceiling(mx_raw * 10000) / 10000
      step <- if (mx > mn) round((mx - mn) / 100, 4) else 0.01
      updateSliderInput(session, "min_edge_w",
                        min   = mn, max = mx, value = mn,
                        step  = step)
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
    r          <- result()
    min_w      <- input$min_edge_w
    filtered_n <- sum(r$weight >= min_w, na.rm = TRUE)
    has_cograph <- requireNamespace("cograph", quietly = TRUE)

    diag <- tags$div(
      style = "font-family: monospace; font-size: 12px; color: #666;
               background: #f8f9fa; padding: 8px 12px; margin-bottom: 12px;
               border-left: 3px solid #2c7be5;",
      sprintf(
        "diagnostics  edges=%d  min_weight=%.6f  max_weight=%.6f  filter_threshold=%.6f  passing=%d  cograph_installed=%s",
        nrow(r), min(r$weight, na.rm = TRUE), max(r$weight, na.rm = TRUE),
        as.numeric(min_w), filtered_n, has_cograph
      )
    )

    if (!has_cograph) {
      return(tagList(diag, tags$div(class = "alert alert-danger",
        tags$strong("Package 'cograph' is not installed on this server."),
        tags$br(),
        "Install it with ",
        tags$code("install.packages('cograph', repos = 'https://mohsaqr.r-universe.dev')"),
        " on the host, then restart the app.")))
    }
    res <- .filtered_cograph(r, min_w)

    body <- if (res$status == "empty") {
      tags$div(class = "alert alert-warning",
               sprintf("No edges with weight >= %.4f. Lower the minimum weight filter.",
                       as.numeric(min_w)))
    } else if (res$status == "error") {
      tags$div(class = "alert alert-danger",
               tags$strong("Could not build the network: "),
               res$message)
    } else if (res$value$n_edges > 3000) {
      tags$div(class = "alert alert-info",
               sprintf("%d edges — too many to render clearly. Raise the minimum weight filter.",
                       res$value$n_edges))
    } else {
      plotOutput("cograph_plot", height = "600px")
    }
    tagList(diag, body)
  })

  output$cograph_plot <- renderPlot({
    req(result())
    req(requireNamespace("cograph", quietly = TRUE))
    res <- .filtered_cograph(result(), input$min_edge_w)
    req(res$status == "ok")

    cograph::splot(
      res$value,
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
