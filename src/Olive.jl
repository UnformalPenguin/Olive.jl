 """
Created in February, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
#### | olive | - | pure julia notebook IDE
Welcome to olive! olive is an integrated development environment written in
julia and for other languages and data editing. Crucially, olive is abstract
    in definition and allows for the creation of unique types for names.
##### Module Composition
- [**Toolips**](https://github.com/ChifiSource/Toolips.jl)
"""
module Olive
#==output[code]
==#
#==|||==#
import Base: write, display, getindex, setindex!, string
using IPyCells
using IPyCells: Cell
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
#==output[code]
==#
#==|||==#
function version()
    srcdir = @__DIR__
    splits = split(srcdir, "/")
    oliveprojdir = join(splits[1:length(splits) - 1], "/")
    projinfo = TOML.parse(read(oliveprojdir * "/Project.toml", String))
    projinfo["version"]
end
#==output[code]
==#
#==|||==#
#==output[TODO]
check out what imma do below: in the module... AHAHAHA
It will require the changing of a lot of arguments though. :)
import Base: cd, mkdir, pwd
import Base: run,
[Base.delete_method(m) for m in methods(cd)]
function cd(s::String)

end
==#
#==|||==#
function olive_module(modname::String, environment::String)
    """module $(modname)
    using Pkg


    function evalin(ex::Any)
            Pkg.activate("$environment")
            ret = eval(ex)
    end
    end"""
end
#==output[code]
==#
#==|||==#
function olive_motd()
    recent_str::String = """# olive editor
    ##### version $(version()) (an alpha)
    Welcome to olive $(version())! This is an early version of olive
    that is meant to demonstrate the basic features, functionalities, and
    capabilities of olive. In the future, this cell will contain release notes;
    you may choose whether you want to keep this here or not! Thanks for trying
    olive!
    """
    tmd("olivemotd", recent_str)::Component{<:Any}
end
#==output[code]
==#
#==|||==#
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
#==output[code]
==#
#==|||==#
include("Core.jl")
include("UI.jl")
#==output[code]
==#
#==|||==#
"""
### route ("/session") (main)
--------------------
This is the function/Route which runs olive's "session" page, the main editor
    for olive. If you are providing this to a server directly with olive
functionality. Note that by  simply providing any server with the `OliveCore`
extension, this route, and also  ways to  populate directories...

It's  pretty smart because with `create` you could  very easily build  a whole
system out of this. I **am** putting this  in  the documentation so you may check
it out. Endemic of future projects? **definitely**
##### example
```
```
"""
main = route("/session") do c::Connection
    # setup base env
    write!(c, olivesheet())
    c[:OliveCore].client_data[getname(c)]["selected"] = "session"
    olmod::Module = c[:OliveCore].olmod
    proj_open::Project{<:Any} = c[:OliveCore].open[getname(c)]
    # setup base UI
    notifier::Component{:div} = olive_notific()
    ui_topbar::Component{:div} = topbar(c)
    style!(ui_topbar, "position" => "sticky")
    ui_explorer::Component{:div} = projectexplorer()
    style!(ui_explorer, "background" => "transparent")
    ui_settings::Component{:section} = settings_menu(c)
    style!(ui_settings, "position" => "sticky")
    ui_explorer[:children] = Vector{Servable}([begin
   Base.invokelatest(olmod.build, c, d, olmod, exp = true)
    end for d in proj_open.directories])
    olivemain::Component{:div} = olive_main(first(proj_open.open)[1])
    style!(olivemain, "overflow-x" => "scroll", "position" => "relative",
    "width" => 100percent, "overflow-y" => "hidden",
    "height" => 90percent, "display" => "inline-flex")
    bod = body("mainbody")
    style!(bod, "overflow" => "hidden")
    push!(bod, notifier,  ui_explorer, ui_topbar, ui_settings, olivemain)
    script!(c, "load", type = "Timeout", time = 250) do cm::ComponentModifier
        load_extensions!(c, cm, olmod)
        window::Component{:div} = Base.invokelatest(olmod.build, c,
        cm, proj_open)
        append!(cm, "olivemain", window)
    end
    write!(c, bod)
end
#==output[code]
==#
#==|||==#
explorer = route("/") do c::Connection
    args = getargs(c)
    notifier::Component{:div} = olive_notific()
    loader_body = div("loaderbody", align = "center")
    style!(loader_body, "margin-top" => 10percent)
    write!(c, olivesheet())
    icon = olive_loadicon()
    bod = body("mainbody")
    if :key in keys(args)
        if ~(args[:key] in keys(c[:OliveCore].client_keys))
            write!(c, "bad key.")
            return
        end
        uname = c[:OliveCore].client_keys[args[:key]]
        if ~(getip(c) in keys(c[:OliveCore].names))
            push!(c[:OliveCore].names, getip(c) => uname)
        end
        c[:OliveCore].names[getip(c)] = uname
        c[:OliveCore].client_data[getname(c)]["selected"] = "files"
        on(c, bod, "load") do cm::ComponentModifier
            olmod = c[:OliveCore].olmod
            homeproj = Directory(c[:OliveCore].data["home"], "root" => "rw")
            workdir = Directory(c[:OliveCore].data["wd"], "all" => "rw")
            dirs = [homeproj, workdir]
            main = olive_main("files")
            for dir in dirs
                push!(main[:children], build(c, dir, olmod))
            end
            script!(c, cm, "loadcallback") do cm
                style!(cm, icon, "opacity" => 0percent)
                set_children!(cm, bod, [olivesheet(), notifier, main])
            end
            load_extensions!(c, cm, olmod)
        end
        push!(loader_body, icon)
        push!(bod, loader_body)
        write!(c, bod)
        return
    end
    coverimg::Component{:img} = olive_cover()
    olivecover = div("topdiv", align = "center")
    logbutt = button("requestaccess", text = "request access")
    on(c, logbutt, "click") do cm::ComponentModifier
        c[:Logger].log(" someone is trying to login to olive! is this you?")
        y = readline()
        if y == "y"
            c[:Logger].log(" okay, logging in as root.")
            key = ToolipsSession.gen_ref(16)
            push!(c[:OliveCore].client_keys[key] => c[:OliveCore].data["root"])
            redirect!(cm, "/?key=$(key)")
        end
    end
    push!(olivecover, coverimg,
    h("mustconfirm", 2, text = "request access (no key)"), logbutt)
    push!(bod, olivecover)
    write!(c, bod)
end
 #==output[code]
 ==#
 #==|||==#
 """
 ### devmode ("/") (devmode)
 --------------------
This is a route that autoloads an active Olive sourceable module -- in addition
to offering some examples.
 ##### example
 ```
 ```
 """
devmode = route("/") do c::Connection
    explorer.page(c)
end
#==output[code]
==#
#==|||==#
#==output[TODO]
I would love for the doc browser to be completed..
I want it to work primarily off of just requests, and client functions.
Other than the search of course. There is a lot more
==#
#==|||==#
docbrowser = route("/doc") do c::Connection
    notifier::Component{:div} = olive_notific()
    write!(c, DOCTYPE())
    write!(c, olivesheet())
    write!(c, notifier)
    if ~(getname(c) in keys(c[:OliveCore].open))~
        # TODO doc for OLMOD
        push!(c[:OliveCore].open, getname(c) => Project{:doc}())
        return
    end
    p::Project{<:Any} = c[:OliveCore].open[getname(c)]
    mod = getarg(c, :mod, first(p.open)[1])
    getdoc = getarg(c, :get, "$(p.name)")
    docs = p.open[mod][:mod].evalin(Meta.parse("@doc($(getdoc))"))
    T = p.open[mod][:mod].evalin(Meta.parse("$(getdoc)"))
    if typeof(T) == Module
        write!(c, h("mod", 1, text = "module"))
    end
    write!(c, h("T", 2, text = string(typeof(T))))
    write!(c, tmd(ToolipsSession.gen_ref(), string(docs)))
end
#==output[code]
==#
#==|||==#
setup = route("/") do c::Connection
    write!(c, olivesheet())
    bod = body("mainbody")
    cells = [Cell(1, "setup", "welcome to olive"),
    Cell(2, "dirselect", c[:OliveCore].data["home"])]
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
    push!(questions, h("questions-name", 2,
    text = "lastly, a username?"))
    namebox::Component{:div} = ToolipsDefaults.textdiv("namesetup",
    text = "root")
    style!(namebox, "outline" => "none", "background-color" => "darkblue",
    "color" => "white", "font-weight" => "bold")
    on(c, namebox, "click") do cm
        set_text!(cm, "namesetup", "")
    end
    push!(questions, namebox)
    confirm_questions = button("conf-q", text = "confirm")
    on(c, confirm_questions, "click") do cm::ComponentModifier
        dfaults = cm[defaults_q]["value"]
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
                 username::String = replace(cm3[namebox]["text"],
                 " " => "_")
                 if ~(isdir(cm["selector"]["text"] * "/olive"))
                     if cm["selector"]["text"] != homedir()
                         srcdir = @__DIR__
                         touch("$srcdir/home.txt")
                         open("$srcdir/home.txt", "w") do o
                             write(o, cm["selector"]["text"])
                         end
                     end
                     create_project(cm["selector"]["text"])
                     config = TOML.parse(read(
                     "$(cm["selector"]["text"])/olive/Project.toml",String))
                     users = Dict{String, Any}(
                     username => Dict{String, Vector{String}}(
                     "group" => ["all", "root"])
                     )
                     push!(config,
                     "olive" => Dict{String, String}("root" => username),
                     "oliveusers" => users)
                     open("$(cm["selector"]["text"])/olive/Project.toml", "w") do io
                         TOML.print(io, config)
                     end
                 end
                 set_text!(cm3, statindicator, "project created !")
                 Pkg.activate("$(cm["selector"]["text"])/olive")
                 Pkg.add("Pkg")
                 cm3[loadbar] = "value" => ".50"
                 style!(cm3, loadbar, "opacity" => 99percent)
                 next!(c, loadbar, cm3) do cm4
                     txt = ""
                     if dfaults == "yes"
                         Pkg.add(
                         url = "https://github.com/ChifiSource/OliveDefaults.jl"
                         )
                         txt = txt * "defaults loaded! "
                     end
                     set_text!(cm4, statindicator, txt)
                     cm4[loadbar] = "value" => "1"
                     style!(cm4, loadbar, "opacity" => 100percent)
                     next!(c, loadbar, cm4) do cm5
                         deleteat!(c.routes, 1)
                         deleteat!(c.routes, 1)
                         oc = c[:OliveCore]
                         direc = cm["selector"]["text"]
                         oc.data["home"] = "$direc/olive"
                         source_module!(oc)
                         push!(c.routes, fourofour, main, explorer)
                         unamekey = ToolipsSession.gen_ref(16)
                         push!(c[:OliveCore].client_keys, unamekey => username)
                         push!(c[:OliveCore].client_data,
                         "emmy" => Dict{String, String}())
                         redirect!(cm5, "/?key=$(unamekey)")
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
#==output[code]
==#
#==|||==#
fourofour = route("404") do c::Connection
    write!(c, p("404message", text = "404, not found!"))
end
#==output[code]
==#
#==|||==#
icons = route("/MaterialIcons.otf") do c::Connection
    srcdir = @__DIR__
    write!(c, Toolips.File(srcdir * "/fonts/MaterialIcons.otf"))
end
mainicon = route("/favicon.ico") do c::Connection
    srcdir = @__DIR__
    write!(c, Toolips.File(srcdir * "/images/favicon.ico"))
end
#==output[code]
==#
#==|||==#
function create_project(homedir::String = homedir(), olivedir::String = "olive")
        try
            cd(homedir)
            Pkg.generate("olive")
        catch
            throw("unable to access your applications directory.")
        end
        open("$homedir/$olivedir/src/olive.jl", "w") do o
            write(o,
            """\"""
            ## welcome to olive!
            Welcome to olive: the extensible notebook application for Julia.
            This is  your olive home module's file. This is where extensions
            for olive can be loaded. If you would  like to make your own
            extension, extend `Olive.build` below... `?(Olive.build)` might
            be helpful. Alternatively, simply use `using` to load extensions
            from modules. For example,
            ```julia
            using OliveDefaults.Styler
            using OlivePy
            ```
            Above all, have fun! Thanks for trying olive! Report any issues to
            [our issues page!](https://github.com/ChifiSource/Olive.jl/issues)
            \"""
            #==|||==#
            module olive
            #==output[code]
            this cell starts the module, you probably don't want to run it.
            ==#
            #==|||==#
            #==output[versioninfo]

            ==#
            #==|||==#
            using Olive
            using Olive.Toolips: Connection
            import Olive: build
            # add extensions here!
            build(oc::OliveCore) = begin
                oc::OliveCore
            end
            #==output[code]
            olive.build
            ==#
            #==|||==#
            # ?build
            #==output[helprepl]

            ==#
            #==|||==#
            end # module
            #==output[code]
            this cell ends the module, you probably don't want to run it.
            ==#
            #==|||==#
            """)
        end
        @info "olive files created! welcome to olive! "
end
#==output[code]
==#
#==|||==#
"""
start(IP::String, PORT::Integer, extensions::Vector{Any}); devmode::Bool = false -> ::Toolips.WebServer
--------------------
The start function comprises routes into a Vector{Route} and then constructs
    a ServerTemplate before starting and returning the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000;
    devmode::Bool = false)
    if devmode
        s = OliveServer(OliveCore("Dev"))
        s.start()
        s[:Logger].log("started new olive server in devmode.")
        return
    end
    srcdir = @__DIR__
    homedirec::String = homedir()
    if isfile("$srcdir/home.txt")
        homedirec = read("$srcdir/home.txt", String)
    end
    oc::OliveCore = OliveCore("olive")
    oc.data["home"] = homedirec
    oc.data["wd"] = pwd()
    rootname::String = ""
    rs::Vector{AbstractRoute} = Vector{AbstractRoute}()
    if ~(isdir("$homedirec/olive"))
        rs = routes(setup, fourofour, icons, mainicon, docbrowser)
    else
        config = TOML.parse(read("$homedirec/olive/Project.toml", String))
        Pkg.activate("$homedirec/olive")
        oc.data = config["olive"]
        rootname = oc.data["root"]
        oc.client_data = config["oliveusers"]
        oc.data["home"] = homedirec * "/olive"
        oc.data["wd"] = pwd()
        source_module!(oc)
        rs = routes(fourofour, main, explorer, docbrowser, icons, mainicon)
    end
    server = WebServer(IP, PORT, routes = rs, extensions = [OliveLogger(),
    oc, Session(["/", "/session", "/doc"])])
    server.start();
    if rootname != ""
        key = ToolipsSession.gen_ref(16)
        push!(oc.client_keys, key => rootname)
        server[:Logger].log(2,
            "link for $(rootname): http://$(IP):$(PORT)/?key=$key")
    end
    server::Toolips.ToolipsServer
end
#==output[code]
==#
#==|||==#
function create(name::String; nodeps::Bool = false)
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add("Olive")
    Pkg.add("TOML")
    Pkg.add("Pkg")
    Pkg.activate("$name/public")
    Pkg.add("Pkg")
    open("$name/src/$name.jl") do io
        write!(io, """
        module $name
        using Olive
        using Olive.Toolips
        using Olive.ToolipsSession
        import Olive: build

        function start(IP::String = "127.0.0.1", PORT::8000)
            oc = OliveCore()
            config = TOML.parse(read("public/Project.toml", String))
            Pkg.activate("public")
            oc.data = config["olive"]
            rootname = oc.data["root"]
            oc.client_data = config["oliveusers"]
            oc.data["home"] = @
            oc.data["wd"] = pwd()
            source_module!(oc)
            rs = routes(fourofour, main, explorer, docbrowser, icons, mainicon)
        end

        end # module
        """)
    end
end
#==output[code]
==#
#==|||==#
function create_extension(name::String; nodeps::Bool = false)
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add("Olive")
    open("$name/src/$name.jl") do io
        write!(io, """
        module $name
        using Olive
        using Olive.Toolips
        using Olive.ToolipsSession
        import Olive: build

        function build(c::Connection, om::OliveModifier,
            oe::OliveExtension{:$name})

        end

        end # module
        """)
    end
end
#==output[code]
==#
#==|||==#
export OliveCore, build, Pkg, TOML, Toolips, ToolipsSession
export OliveExtension, OliveModifier, Cell
#==output[code]
==#
#==|||==#
end # - module
#==output[code]
==#
#==|||==#
