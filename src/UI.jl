#==
Default
    Styles
==#
function cell_in()
    cellin = Animation("cell_in", length = 1.5)
    cellin[:from] = "opacity" => "0%"
    cellin[:from] = "transform" => "translateY(100%)"
    cellin[:to] = "opacity" => "100%"
    cellin[:to] = "transform" =>  "translateY(0%)"
    cellin
end

function usingcell_style()
    st::Style = Style("div.usingcell", border = "0px solid gray", padding = "40px",
    "border-radius" => 5px, "background-color" => "#CCCCFF")
    animate!(st, cell_in()); st::Style
end

function cell_style()
    st::Style = Style("div.cell", "border-color" => "gray", padding = "20px",
    "background-color" => "white")
    st:"focus":["border-width" => 2px]
    animate!(st, cell_in())
    st::Style
end

function inputcell_style()
    st = Style("div.input_cell", border = "2px solid gray", padding = "20px",
    "bordier-radius" => 30px, "margin-top" => 30px, "transition" => 1seconds,
    "font-size" => 14pt)
    animate!(st, cell_in())
    st:"focus":["border-width" => 5px, "border-color" => "orange"]
    st::Style
end

function outputcell_style()
    st = Style("div.output_cell", border = "0px", padding = "10px",
    "margin-top" => 20px, "margin-right" => 200px, "border-radius" => 30px,
    "font-size" => 14pt)
    animate!(st, cell_in())
    st::Style
end

hdeps_style() = Style("h1.deps", color = "white")

google_icons() = link("google-icons",
href = "https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200",
rel = "stylesheet")

function iconstyle()
    s = Style(".material-symbols-outlined", cursor = "pointer",
    "font-size" => "100pt", "transition" => ".4s")
    s:"hover":["color" => "orange", "transform" => "scale(1.1)"]
    s
end
function cellnumber_style()
    st = Style("h1.cell_number", color = "lightblue")
    st["font-family"] = "'Rubik', sans-serif"
    st
end

function ipy_style()
    s::Style = Style("div.cell-ipynb",
    "background-color" => "orange",
     "width" => 75percent, "overflow-x" => "hidden", "border-color" => "gray",
     "border-width" => 2px,
    "padding" => 4px, "border-style" => "solid", "transition" => "0.5s")
    s:"hover":["scale" => "1.05"]
    s::Style
end

function toml_style()
    Style("div.cell-toml", "background-color" => "blue", "text-color" => "white",
    "border-width" => 2px, "overflow-x" => "hidden", "padding" => 4px,
    "transition" => "0.5s",
    "border-style" => "solid", "width" => 75percent)
end

function jl_style()
    s = Style("div.cell-jl", "background-color" => "#F55887", "text-color" => "white",
    "border-width" => 2px, "overflow-x" => "hidden", "padding" => 4px,
    "border-style" => "solid", "width" => 75percent, "transition" => "0.5s")
    s:"hover":["scale" => "1.05"]
    s::Style
end

function hidden_style()
    Style("div.cell-hidden",
    "background-color" => "gray",
     "width" => 75percent, "overflow-x" => "hidden",
    "padding" => 4px, "transition" => "0.5s")::Style
end

function julia_style()
    hljl_nf::Style = Style("span.hljl-nf", "color" => "#2B80FA")
    hljl_oB::Style = Style("span.hljl-oB", "color" => "purple", "font-weight" => "bold")
    hljl_n::Style = Style("span.hljl-ts", "color" => "orange")
    hljl_cs::Style = Style("span.hljl-cs", "color" => "gray")
    hljl_k::Style = Style("span.hljl-k", "color" => "#E45E9D", "font-weight" => "bold")
    hljl_s::Style = Style("span.hljl-s", "color" => "#3FBA41")
    styles::Component{:sheet} = Component("codestyles", "sheet")
    push!(styles, hljl_k, hljl_nf, hljl_oB, hljl_n, hljl_cs, hljl_s)
    styles::Component{:sheet}
end

function olivesheet()
    st = ToolipsDefaults.sheet("olivestyle", dark = false)
    bdy = Style("body", "background-color" => "white")
    push!(st, google_icons(),
    cell_in(), iconstyle(), cellnumber_style(), hdeps_style(),
    usingcell_style(), outputcell_style(), inputcell_style(), bdy, ipy_style(),
    hidden_style(), jl_style(), toml_style())
    st
end

function olivesheetdark()
    st = ToolipsDefaults.sheet("olivestyle", dark = true)
    bdy = Style("body", "background-color" => "#360C1F", "transition" => ".8s")
    st[:children]["div"]["background-color"] = "#DB3080"
    st[:children]["div"]["color"] = "white"
    st[:children]["p"]["color"] = "white"
    st[:children]["h1"]["color"] = "orange"
    st[:children]["h2"]["color"] = "lightblue"
    ipc = inputcell_style()
    ipc["background-color"] = "#DABCDF"
    ipc["border-width"] = 0px
    push!(st, google_icons(),
    cell_in(), iconstyle(), cellnumber_style(), hdeps_style(),
    usingcell_style(), outputcell_style(), ipc, bdy, ipy_style(),
    hidden_style(), jl_style(), toml_style())
    st
end

function projectexplorer()
    pexplore = divider("projectexplorer")
    style!(pexplore, "background" => "transparent", "position" => "fixed",
    "z-index" => "1", "top" => "0", "overflow-x" => "hidden",
     "padding-top" => "30px", "width" => "0", "height" => "100%", "left" => "0",
     "transition" => "0.8s")
    pexplore
end

function explorer_icon(c::Connection)
    explorericon = topbar_icon("explorerico", "drive_file_move_rtl")
    on(c, explorericon, "click") do cm::ComponentModifier
        if cm["olivemain"]["ex"] == "0"
            style!(cm, "projectexplorer", "width" => "250px")
            style!(cm, "olivemain", "margin-left" => "250px")
            style!(cm, explorericon, "color" => "lightblue")
            set_text!(cm, explorericon, "folder_open")
            cm["olivemain"] = "ex" => "1"
        else
            style!(cm, "projectexplorer", "width" => "0px")
            style!(cm, "olivemain", "margin-left" => "0px")
            set_text!(cm, explorericon, "drive_file_move_rtl")
            style!(cm, explorericon, "color" => "black")
            cm["olivemain"] = "ex" => "0"
        end
    end
    explorericon::Component{:span}
end

function dark_mode(c::Connection)
    darkicon = topbar_icon("darkico", "dark_mode")
    on(c, darkicon, "click") do cm::ComponentModifier
        if cm["olivestyle"]["dark"] == "false"
            set_text!(cm, darkicon, "light_mode")
            set_children!(cm, "olivestyle", olivesheetdark()[:children])
            cm["olivestyle"] = "dark" => "true"
        else
            set_text!(cm, darkicon, "dark_mode")
            set_children!(cm, "olivestyle", olivesheet()[:children])
            cm["olivestyle"] = "dark" => "false"
        end
    end
    darkicon::Component{:span}
end

function settings(c::Connection)
    settingicon = topbar_icon("settingicon", "settings")
    settingicon::Component{:span}
end

function cellmenu(c::Connection)
    cellicon = topbar_icon("editico", "notes")
    cellicon::Component{:span}
end

function topbar(c::Connection)
    topbar = divider("menubar")
    leftmenu = span("leftmenu", align = "left")
    style!(leftmenu, "display" => "inline-block")
    rightmenu = span("rightmenu", align = "right")
    style!(rightmenu, "display" => "inline-block", "float" => "right")
    style!(topbar, "border-style" => "solid", "border-color" => "black",
    "border-radius" => "5px")
    push!(leftmenu, explorer_icon(c), cellmenu(c))
    push!(rightmenu, settings(c))
    push!(topbar, leftmenu, rightmenu)
    topbar::Component{:div}
end

function topbar_icon(name::String, icon::String)
    ico = span(name, class = "material-symbols-outlined", text = icon,
     margin = "15px")
     style!(ico, "font-size" => "35pt")
     ico
end