# Load packages -----------------------------------------------------
library(shiny)
library(dplyr)
library(tidyr)
library(DT)
library(highcharter)
library(shinyWidgets)
library(leaflet)

# Load data ---------------------------------------------------------
births <- read.csv("data/births.csv")
r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()


# Determine years in data -------------------------------------------
years <- unique(births$year)

# UI ----------------------------------------------------------------
ui <- fluidPage(
    
    # App title -------------------------------------------------------
    titlePanel("The Friday the 13th effect"),
    
    # Sidebar layout with a input and output definitions --------------
    sidebarLayout(
        
        # Inputs --------------------------------------------------------    
        sidebarPanel(
            
            sliderInput("year", 
                        label = "Year",
                        min = min(years), 
                        max = max(years), 
                        step = 1,
                        sep = "",
                        value = range(years)),
            
            actionButton("recalc", "New points"),
            
            
            prettyCheckbox(
                inputId = "pretty_1", label = "Check me!", icon = icon("check")
            ),
            prettyCheckbox(
                inputId = "pretty_2", label = "Check me!", icon = icon("thumbs-up"), 
                status = "default", shape = "curve", animation = "pulse"
            ),
            prettyCheckbox(
                inputId = "pretty_3", label = "Check me!", icon = icon("users"), 
                animation = "pulse", plain = TRUE, outline = TRUE
            ),
            prettyCheckbox(
                inputId = "pretty_4", label = "Check me!",
                status = "success", outline = TRUE
            ),
            prettyCheckbox(
                inputId = "pretty_5", label = "Check me!",
                shape = "round", outline = TRUE, status = "info"
            ),
            
            selectInput("plot_type", 
                        label = "Plot type",
                        choices = c("Scatter" = "scatter", 
                                    "Bar" = "column", 
                                    "Line" = "line")),
            selectInput("theme", 
                        label = "Theme",
                        choices = c("No theme", 
                                    "Chalk" = "chalk",
                                    "Dark Unica" = "darkunica", 
                                    "Economist" = "economist",
                                    "FiveThirtyEight" = "fivethirtyeight", 
                                    "Gridlight" = "gridlight", 
                                    "Handdrawn" = "handdrawn", 
                                    "Sandsignika" = "sandsignika"))
        ),
        
        # Output --------------------------------------------------------    
        mainPanel(
            highchartOutput("hcontainer", height = "500px"),
            highchartOutput('hcontainer2', height = '500px'),
            DT::dataTableOutput('datatable1'),
            leafletOutput("mymap")
        )
        
    )
)


# SERVER ------------------------------------------------------------
server = function(input, output) {
    
    # Calculate differences between 13th and avg of 6th and 20th ------
    diff13 <- reactive({
        births %>%
            filter(between(year, input$year[1], input$year[2])) %>%
            filter(date_of_month %in% c(6, 13, 20)) %>%
            mutate(day = ifelse(date_of_month == 13, "thirteen", "not_thirteen")) %>%
            group_by(day_of_week, day) %>%
            summarise(mean_births = mean(births)) %>%
            arrange(day_of_week) %>%
            spread(day, mean_births) %>%
            mutate(diff_ppt = ((thirteen - not_thirteen) / not_thirteen) * 100)
    })
    
    # Text string of selected years for plot subtitle -----------------
    selected_years_to_print <- reactive({
        if(input$year[1] == input$year[2]) { 
            as.character(input$year[1])
        } else {
            paste(input$year[1], " - ", input$year[2])
        }
    })
    
    # Highchart -------------------------------------------------------
    output$hcontainer <- renderHighchart({
        
        hc <- highchart() %>%
            hc_add_series(data = diff13()$diff_ppt, 
                          type = input$plot_type,
                          name = "Difference, in ppt",
                          showInLegend = FALSE) %>%
            hc_yAxis(title = list(text = "Difference, in ppt"), 
                     allowDecimals = FALSE) %>%
            hc_xAxis(categories = c("Monday", "Tuesday", "Wednesday", "Thursday", 
                                    "Friday", "Saturday", "Sunday"),
                     tickmarkPlacement = "on",
                     opposite = TRUE) %>%
            hc_title(text = "The Friday the 13th effect",
                     style = list(fontWeight = "bold")) %>% 
            hc_subtitle(text = paste("Difference in the share of U.S. births on 13th 
                               of each month from the average of births on the 6th 
                               and the 20th,",
                                     selected_years_to_print())) %>%
            hc_tooltip(valueDecimals = 4,
                       pointFormat = "Day: {point.x} <br> Diff: {point.y}") %>%
            hc_credits(enabled = TRUE, 
                       text = "Sources: CDC/NCHS, SOCIAL SECURITY ADMINISTRATION",
                       style = list(fontSize = "10px"))
        
        # Determine theme and apply to highchart ------------------------
        if (input$theme != "No theme") {
            theme <- switch(input$theme,
                            chalk = hc_theme_chalk(),
                            darkunica = hc_theme_darkunica(),
                            fivethirtyeight = hc_theme_538(),
                            gridlight = hc_theme_gridlight(),
                            handdrawn = hc_theme_handdrawn(),
                            economist = hc_theme_economist(),
                            sandsignika = hc_theme_sandsignika()
            )
            hc <- hc %>%
                hc_add_theme(theme)
        }
        
        # Print highchart -----------------------------------------------
        hc
    })
    
    
    # Highchart -------------------------------------------------------
    output$hcontainer2 <- renderHighchart({
        
        data <- tibble(
            country = 
                c("PT", "IE", "GB", "IS",
                  
                  "NO", "SE", "DK", "DE", "NL", "BE", "LU", "ES", "FR", "PL", "CZ", "AT",
                  "CH", "LI", "SK", "HU", "SI", "IT", "SM", "HR", "BA", "YF", "ME", "AL", "MK",
                  
                  "FI", "EE", "LV", "LT", "BY", "UA", "MD", "RO", "BG", "GR", "TR", "CY",
                  
                  "RU"),  
            tz = c(rep("UTC", 4), rep("UTC + 1",25), rep("UCT + 2",12), "UTC + 3")
        )
        
        # auxiliar variable
        data <- data %>% 
            mutate(value = cumsum(!duplicated(tz)))
        
        
        # now we'll create the dataClasses
        dta_clss <- data %>% 
            mutate(value = cumsum(!duplicated(tz))) %>% 
            group_by(tz) %>% 
            summarise(value = unique(value)) %>% 
            arrange(value) %>% 
            rename(name = tz, from = value) %>% 
            mutate(to = from + 1) %>% 
            list_parse()
        
        hcmap(
            map = "custom/europe",
            data = data, 
            joinBy = c("iso-a2","country"),
            name = "Time zone",
            value = "value",
            tooltip = list(pointFormat = "{point.name} {point.tz}"),
            dataLabels = list(enabled = TRUE, format = "{point.country}")
        ) %>%
            hc_colorAxis(
                dataClassColor = "category",
                dataClasses = dta_clss
            ) %>% 
            hc_title(text = "Europe Time Zones")
        
        
        
    })
    
    output$datatable1 <- DT::renderDT({
        m = as.data.frame(round(matrix(rnorm(100), 5), 5))
        DT::datatable(
            m, extensions = 'FixedColumns',
            options = list(
                dom = 't',
                scrollX = TRUE,
                fixedColumns = TRUE
            )
        )
    })
    
    points <- eventReactive(input$recalc, {
        cbind(rnorm(40) * 2 + 13, rnorm(40) + 48)
    }, ignoreNULL = FALSE)
    output$mymap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Stamen.TonerLite,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>%
            addMarkers(data = points())
    })
    
}

# Run app -----------------------------------------------------------
shinyApp(ui = ui, server = server)