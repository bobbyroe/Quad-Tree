do ->

    log = console.log.bind console
    d = document
    canvas = d.getElementById 'main'
    info_panel = d.getElementById 'info'
    ctx = canvas.getContext '2d'
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight - 2

    pre_canvas = d.createElement 'canvas'
    pre_canvas.width = canvas.width
    pre_canvas.height = canvas.height
    pre_ctx = pre_canvas.getContext '2d'

    pre_ctx.lineWidth = "1"
    pre_ctx.strokeStyle = "red"
    pre_ctx.fillStyle = "#445544"
    colors = ['red', 'green', 'blue', 'yellow'] # , 'orange', 'purple']
    fill_colors = ['#000000', '#111111', '#202020', '#333333','#404040', '#555555', '#606060', '#777777', '#888888', '#999999', '#a0a0a0', '#bbbbbb', '#c0c0c0', '#dddddd', '#e0e0e0', '#FFFFFF']
    drag = 1 - 0.002
    mouse = 
        x: 0
        y: 0

    is_highlighing_points = true

    addNewPoint = ->
        p = new Point()
        points.push p
        quad_tree.add p

    getNodeForPoint = (x, y) ->

    past_now = (new Date()).getTime() * 0.001
    fps_el = d.getElementById 'fps'
    update_fps = ->
        # Compute the elapsed time since the last rendered frame
        # in seconds.
        now = (new Date()).getTime() * 0.001
        elapsed_time = now - past_now
        past_now = now

        # Update the FPS timer.
        fps_timer.update elapsed_time
        fps_el.textContent = "#{fps_timer.average_FPS} fps"

    points = []
    class Point

        constructor: (@x, @y) ->
            @x = (Math.random() * 100 - 50) + canvas.width * 0.5
            @y = (Math.random() * 100 - 50) + canvas.height * 0.5
            @vel =
                x: Math.random() * 4 - 2
                y: Math.random() * 4 - 2
            @color = 'cyan' # colors[Math.floor(Math.random() * colors.length)]
            @size = 5 # Math.floor Math.random() * 7 + 3
            @drag = drag
            @ctx = pre_ctx

        update: ->
            @vel.x *= @drag
            @vel.y *= @drag
            @x += @vel.x
            @y += @vel.y
            @checkBounds()

        checkBounds: ->
            if @x < 0 or @x > canvas.width - @size then @vel.x *= -1
            if @y < 0 or @y > canvas.height - @size then @vel.y *= -1

        draw: ->
            mag = @vel.x * @vel.x + @vel.y * @vel.y # Math.sqrt 
            @ctx.fillStyle = "hsl(#{(mag) * 60 + 210}, 100%, 50%"# @color
            @ctx.fillRect @x, @y, @size, @size

        highlight: ->
            @ctx.lineWidth = "2"
            @ctx.strokeStyle = 'white'
            @ctx.beginPath()
            @ctx.rect @x - 2, @y - 2, @size + 4, @size + 4
            @ctx.stroke()

    class Node

        constructor: (@x, @y, @width, @height, @level = 0) ->
            @objs = []
            @max_objs = 10
            @max_levels = 6
            @sub_nodes = []
            @color = 'green' # colors[@index]
            @ctx = pre_ctx
            @obj_color = 0
            @mult = 255 / @max_objs

        draw: ->
            @ctx.strokeStyle = @color # if is_moused then 'red' else @color
            @obj_color = @objs.length * @mult
            @ctx.fillStyle = if @objs.length < @max_objs + 1 then "rgba(#{Math.floor(@obj_color)}, #{Math.floor(@obj_color)}, #{Math.floor(@obj_color)}, 0.2)" else '#FFFFFF'
            # @ctx.beginPath()
            # @ctx.rect @x, @y, @width, @height
            @ctx.fillRect @x, @y, @width, @height
            # @ctx.stroke()

            for node in @sub_nodes
                node.draw()

        add: (obj) ->
            if @sub_nodes.length isnt 0
                index = @getIndex obj
                if index isnt -1
                    @sub_nodes[index].add obj
                    return

            @objs.push obj

            if @objs.length > @max_objs and @level < @max_levels
                if @sub_nodes.length is 0 then @split()

                for obj in @objs
                    index = @getIndex obj
                    if index isnt -1
                        @sub_nodes[index].add obj
                        @remove obj

        getIndex: (obj) ->
            index = -1
            midpoint =
                x: @x + @width * 0.5
                y: @y + @height * 0.5
            if obj.x < midpoint.x and obj.y < midpoint.y then index = 0 # TOP LEFT
            if obj.x > midpoint.x and obj.y < midpoint.y then index = 1 # TOP RIGHT
            if obj.x > midpoint.x and obj.y > midpoint.y then index = 2 # BOT RIGHT
            if obj.x < midpoint.x and obj.y > midpoint.y then index = 3 # BOT LEFT

            index

        getNearbyObjs: (obj) ->
            objs = @objs.slice 0
            index = @getIndex obj
            if index isnt -1 and @sub_nodes.length isnt 0
                return @sub_nodes[index].getNearbyObjs obj
            objs

        remove: (obj) ->
            index = @objs.indexOf obj
            if index isnt -1
                @objs = @objs.slice 0, index

        split: ->
            half_width = @width * 0.5
            half_height = @height * 0.5
            level = @level + 1
            x = @x
            y = @y

            @sub_nodes[0] = new Node x, y, half_width, half_height, level                            # TOP LEFT
            @sub_nodes[1] = new Node x + half_width, y, half_width, half_height, level               # TOP RIGHT
            @sub_nodes[2] = new Node x + half_width, y + half_height, half_width, half_height, level # BOT RIGHT
            @sub_nodes[3] = new Node x, y + half_height, half_width, half_height, level              # BOT LEFT

        clear: ->
            @objs = []
            if @sub_nodes.length isnt 0
                for node in @sub_nodes
                    node.clear()
            @sub_nodes = []


    class FPS

      @NUM_FRAMES_TO_AVERAGE: 16

      constructor: ->
        @total_time_ = FPS.NUM_FRAMES_TO_AVERAGE

        @time_table_ = []

        @time_table_cursor_ = 0

        for tt in [0..FPS.NUM_FRAMES_TO_AVERAGE - 1]
          @time_table_[tt] = 1.0
      
      update: (elapsed_time) ->
        @total_time_ += elapsed_time - @time_table_[@time_table_cursor_]

        @time_table_[@time_table_cursor_] = elapsed_time

        ++@time_table_cursor_
        if @time_table_cursor_ is FPS.NUM_FRAMES_TO_AVERAGE then @time_table_cursor_ = 0

        @instantaneous_FPS = Math.floor 1.0 / elapsed_time + 0.5
        @average_FPS = Math.floor (1.0 / (@total_time_ / FPS.NUM_FRAMES_TO_AVERAGE)) + 0.5


    #
    #
    #
    fps_timer = new FPS()
    quad_tree = new Node 0, 0, canvas.width, canvas.height
    window.quad_tree = quad_tree

    for i in [0..1000]
        addNewPoint()

    hot_points = []
    renderFrame = -> 
        requestAnimationFrame(renderFrame) 

        pre_ctx.clearRect 0, 0, pre_canvas.width, pre_canvas.height
        ctx.clearRect 0, 0, canvas.width, canvas.height

        quad_tree.clear()
        for p in points
            p.update()
            quad_tree.add p
            p.draw()

        if is_highlighing_points is true
            hot_points = quad_tree.getNearbyObjs mouse
            for point in hot_points
                point.highlight()

        quad_tree.draw()
        ctx.drawImage pre_canvas, 0, 0
        update_fps()
    
    renderFrame()

    showInfoPanel = ->
        canvas.classList.add 'scooched_right'
        info_panel.classList.add 'open'
        is_highlighing_points = false

    hideInfoPanel = ->
        canvas.classList.remove 'scooched_right'
        info_panel.classList.remove 'open'
        is_highlighing_points = true

    toggleInfoPanel = ->
        if info_panel.classList.contains 'open'
            hideInfoPanel()
        else 
            showInfoPanel()

    keyDowned = (evt) ->
        SPACE = 32
        key_pressed = evt.keyCode
        if key_pressed is SPACE then addNewPoint()

    # docClicked = (evt) ->
    #     node = getNodeForPoint evt.clientX, evt.clientY
    mouseMoved = (evt) ->
        mouse = 
            x: evt.clientX
            y: evt.clientY

    clicked = (evt) ->
        if evt.target.id is 'nub'
            toggleInfoPanel();
        if evt.target.id is 'main'
            hideInfoPanel();

    mousedOver = (evt) ->
        # log log evt.target.id

    d.addEventListener 'keydown', keyDowned
    d.addEventListener 'mousemove', mouseMoved
    d.addEventListener 'click', clicked
    d.addEventListener 'mouseover', mousedOver
