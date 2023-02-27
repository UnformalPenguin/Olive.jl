 """
Created in February, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
#### | olive | - | custom developer |
Welcome to olive! olive is an integrated development environment written in
julia and for other languages and data editing. Crucially, olive is abstract
    in definition and allows for the creation of unique types for names.
##### Module Composition
- [**Toolips**](https://github.com/ChifiSource/Toolips.jl)
"""
module Olive
import Base: write, display, getindex, setindex!
using IPy
using IPy: Cell
using Pkg
using Toolips
import Toolips: AbstractRoute, AbstractConnection, AbstractComponent, Crayon, write!, Modifier
using ToolipsSession
import ToolipsSession: bind!, AbstractComponentModifier
using ToolipsDefaults
using ToolipsMarkdown
using ToolipsBase64
using TOML
using Revise


#==
- Olive.jl./src/Olive.jl
-- deps/includes  (you are here)
-- default routes
-- extension loader
-- Server Defaults
- [Core.jl](./src/Core.jl)
-- OliveExtensions
-- OliveModifiers
-- Directories
-- Projects
-- server extension
-- display
-- filetracker
- [UI.jl](./src/UI.jl)
-- styles
- [Extensions.jl](./src/Extensions.jl)
==#

include("Core.jl")
include("UI.jl")

"""
main(c::Connection) -> _
--------------------
This function is temporarily being used to test Olive.

"""
main = route("/session") do c::Connection
    c[:OliveCore].client_data[getip(c)][:selected] = "session"
    write!(c, olivesheet())
    proj_open::Project{<:Any} = c[:OliveCore].open[getip(c)]
    ui_topbar::Component{:div} = topbar(c)
    ui_explorer::Component{:div} = projectexplorer()
    olivemain::Component{:div} = olive_main(first(proj_open.open)[1])
    ui_tabs::Vector{Servable} = Vector{Servable}()
    ui_explorer[:children] = [olive_loadicon()]
    bod = body("mainbody")
    push!(bod, ui_explorer, olivemain)
    if ~(:keybindings in keys(c[:OliveCore].client_data[getip(c)]))
        c[:OliveCore].client_data[getip(c)][:keybindings] = Dict(
        :evaluate => ("Enter", :shift),
        :delete => ("Delete", :ctrl, :shift),
        :up => ("ArrowUp", :ctrl, :shift),
        :down => ("ArrowDown", :ctrl, :shift),
        :copy => ("C", :ctrl, :shift),
        :paste => ("V", :ctrl, :shift),
        :cut => ("X", :ctrl, :shift),
        :new => ("Q", :ctrl, :shift)
        )
    end
    olmod::Module = c[:OliveCore].olmod
    mainpane = div("olivemain-pane")
    homeproj = Directory(c[:OliveCore].data[:home], "root" => "rw")
    directories = [homeproj]
    ui_explorer[:children] = Vector{Servable}([begin
   Base.invokelatest(olmod.build, c, d, olmod)
    end for d in directories])
    push!(olivemain, ui_topbar, mainpane)
    on(c, "load") do cm::ComponentModifier
        proj_open.directories = [homeproj]
        load_extensions!(c, cm, olmod)
        cells::Vector{Servable} = Base.invokelatest(olmod.build, c,
        cm, proj_open)
        mainpane[:children] = cells
        set_children!(cm, "olivemain-pane", [mainpane])
    end
    write!(c, bod)
end

explorer = route("/") do c::Connection
    c[:OliveCore].client_data[getip(c)][:selected] = "files"
    loader_body = div("loaderbody", align = "center")
    style!(loader_body, "margin-top" => 10percent)
    write!(c, olivesheet())
    icon = olive_loadicon()
    bod = olive_body(c)
    on(c, bod, "load") do cm::ComponentModifier
        olmod = c[:OliveCore].olmod
        homeproj = Directory(c[:OliveCore].data[:home], "root" => "rw")
        dirs = [homeproj]
        main = olive_main("files")
        for dir in dirs
            push!(main[:children], build(c, dir, olmod))
        end
        script!(c, cm, "loadcallback") do cm
            style!(cm, icon, "opacity" => 0percent)
            set_children!(cm, bod, [olivesheet(), main])
        end
        load_extensions!(c, cm, olmod)
    end
    push!(loader_body, icon)
    push!(bod, loader_body)
    write!(c, bod)
 end



dev = route("/") do c::Connection
    explorer.page(c)
end

setup = route("/") do c::Connection
    write!(c, olivesheet())
    bod = body("mainbody")
    cells = [Cell(1, "setup", "welcome to olive"),
    Cell(2, "dirselect", c[:OliveCore].data[:home])]
    built_cells = Vector{Servable}([build(c, cell) for cell in cells])
    bod[:children] = built_cells
    confirm_button = button("confirm", text = "confirm")
    questions = section("questions")
    style!(questions, "opacity" => 0percent, "transition" => 2seconds,
    "transform" => "translateY(50%)")
    push!(questions, h("questions-heading", 2, text = "a few more things ..."))
    opts = [button("yes", text = "yes"), button("no", text = "no")]
    push!(questions, h("questions-defaults", 4, text = "would you like to add OliveDefaults?"))
    push!(questions, p("defaults-explain", text = """this extension will give the
    capability to add custom styles, adds more cells, and more!"""))
    defaults_q = ToolipsDefaults.button_select(c, "defaults_q", opts)
    push!(questions, defaults_q)
    push!(questions, h("questions-download", 4,
     text = "would you like to download olive icons?"))
     push!(questions, p("download-explain", text = """this will download
     a CSS file that provides Olive's material icons, meaning you will still
     have icons while offline, and they will load faster. (requires an internet connection)"""))
    opts2 = [button("yesd", text = "yes"), button("nod", text = "no")]
    download_q = ToolipsDefaults.button_select(c, "download_q", opts2)
    push!(questions, download_q)
    confirm_questions = button("conf-q", text = "confirm")
    on(c, confirm_questions, "click") do cm::ComponentModifier
        dfaults = cm[defaults_q]["value"]
        dload = cm[download_q]["value"]
        statindicator = a("statind", text = "okay! i'll get this set up for you.")
        loadbar = ToolipsDefaults.progress("oliveprogress", value = "0")
        style!(loadbar, "webkit-progreess-value" => "pink", "background-color" => "orange",
         "radius" => 4px, "transition" => 1seconds, "width" => 0percent,
         "opacity" => 0percent)
         append!(cm, bod, loadbar)
         append!(cm, questions, br())
         append!(cm, questions, statindicator)
         style!(cm, questions, "border-radius" => 0px)
         next!(c, questions, cm) do cm2
             set_text!(cm2, statindicator, "setting up olive ...")
             style!(cm2, loadbar, "opacity" => 100percent, "width" => 100percent)
             next!(c, loadbar, cm2) do cm3
                 if ~(isdir(cm["selector"]["text"] * "/olive"))
                     create_project(cm["selector"]["text"])
                 end
                 set_text!(cm3, statindicator, "project created !")
                 cm3[loadbar] = "value" => ".50"
                 style!(cm3, loadbar, "opacity" => 99percent)
                 next!(c, loadbar, cm3) do cm4
                     txt = ""
                     if dfaults == "yes"
                         alert!(cm4, "defaults not yet implemented")
                         txt = txt * "defaults loaded! "
                     end
                     if dload == "yes"
                         alert!(cm4, "download not yet implemented")
                         txt = txt * "downloaded icons!"
                     end
                     set_text!(cm4, statindicator, txt)
                     cm4[loadbar] = "value" => "1"
                     style!(cm4, loadbar, "opacity" => 100percent)
                     next!(c, loadbar, cm4) do cm5
                         deleteat!(c.routes, 1)
                         deleteat!(c.routes, 1)
                         oc = c[:OliveCore]
                         direc = cm["selector"]["text"]
                         oc.data[:home] = "$direc/olive"
                         olmod = eval(Meta.parse(read("$direc/olive/src/olive.jl", String)))
                         Base.invokelatest(olmod.build, oc)
                         oc.olmod = olmod
                         push!(c.routes, fourofour, main, explorer)
                         redirect!(cm5, "/")
                     end
                 end
             end
         end
    end
    push!(questions, confirm_questions)
    on(c, confirm_button, "click") do cm::ComponentModifier
        selected = cm["selector"]["text"]
        insert!(questions[:children], 1, h("selector", 1, text = selected))
        [style!(cm, b_cell, "transform" => "translateX(-110%)", "transition" => 2seconds) for b_cell in built_cells]
        style!(cm, confirm_button, "transform" => "translateX(-120%)", "transition" => 2seconds)
        append!(cm, bod, questions)
        next!(c, confirm_button, cm) do cm2
            [remove!(cm2, b_cell) for b_cell in built_cells]
            style!(cm2, questions, "transform" => "translateY(0%)", "opacity" => 100percent)
        end
        #
    end
    push!(bod, confirm_button)
    write!(c, bod)
end

fourofour = route("404") do c::Connection
    write!(c, p("404message", text = "404, not found!"))
end

function create_project(homedir::String = homedir(), olivedir::String = "olive")
        try
            cd(homedir)
            Pkg.generate("olive")
        catch
            throw("unable to access your applications directory.")
        end
        open("$homedir/$olivedir/src/olive.jl", "w") do o
            write(o, """
            module $olivedir
            using Olive
            import Olive: build

            build(oc::OliveCore) = begin
                oc::OliveCore
            end

            end # module""")
        end
        @info "olive files created! welcome to olive! "
end

"""
start(IP::String, PORT::Integer, extensions::Vector{Any}) -> ::Toolips.WebServer
--------------------
The start function comprises routes into a Vector{Route} and then constructs
    a ServerTemplate before starting and returning the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000;
    devmode::Bool = false)
    if devmode
        s = OliveDevServer(OliveCore("Dev"))
        s.start()
        s[:Logger].log("started new olive server in devmode.")
        return
    end
    oc::OliveCore = OliveCore("olive")
    oc.data[:wd] = pwd()
    oc.data[:home] = homedir()
    homedirec = oc.data[:home]
    rs::Vector{AbstractRoute} = Vector{AbstractRoute}()
    if ~(isdir("$homedirec/olive"))
        rs = routes(setup, fourofour)
    else
        Pkg.activate("$homedirec/olive")
        oc.data[:home] = "$homedirec/olive"
        olmod = eval(Meta.parse(read("$homedirec/olive/src/olive.jl", String)))
        Base.invokelatest(olmod.build, oc)
        oc.olmod = olmod
        rs = routes(fourofour, main, explorer)
    end
    server = WebServer(IP, PORT, routes = rs, extensions = [OliveLogger(),
    oc, Session(["/", "/session"])])
    server.start(); server::Toolips.ToolipsServer
end

OliveServer(oc::OliveCore) = WebServer(extensions = [oc, OliveLogger(),
Session(["/", "/session"])])

OliveDevServer(oc::OliveCore) = begin
    rs = routes(dev, fourofour, main)
    WebServer(extensions = [oc, OliveLogger(), Session(["/", "/session"])],
    routes = rs)
end

#== TODO Create creates a new server at the current directory, making Olive.jl
deployable!
==#
function create(name::String)
    Toolips.new_webapp(name)
    Pkg.add(url = "https://github.com/ChifiSource/Olive.jl")
    open("$name/src/$name.jl") do io
        write!(io, """
        module $name
        using Toolips
        using ToolipsSession
        using Olive
        import Olive: build

        build(oc::OliveCore) = begin
            oc::OliveCore
        end

        build(om::OliveModifier, oe::OliveExtension{:$name})

        end

        function start()

        end

        end # module
        """)
    end
end

export OliveCore, build, Pkg, TOML, Toolips, ToolipsSession
end # - module
