# require("modulereg").registerModule __filename, (require __filename)

# import * as Detector  from './detector'
# import * as Color     from 'basegl/display/Color'

# import {POINTER_EVENTS}      from 'basegl/display/DisplayObject'
# import {group}      from 'basegl/display/Symbol'
# import * as Symbol from 'basegl/display/Symbol'
import {circle}      from 'basegl/display/Shape'
# import {Navigator}      from 'basegl/navigation/Navigator'
# import {world}      from 'basegl/display/World'
import * as basegl from 'basegl'
# import * as Shape     from 'basegl/display/Shape'

# M = require 'basegl/math/Common'


# import * as Animation from 'basegl/animation/Animation'
# import * as Easing    from 'basegl/animation/Easing'

# import {BoxSelector} from 'basegl/display/Selection'
# import * as Font from 'basegl/display/text/sdf/Atlas'


# import {animationManager} from 'basegl/animation/Manager'


# # animationManager.fpsLimit = 60
# # animationManager.maxMissingFrames = 1

# #######################
# ### Node Definition ###
# #######################

# nodeRadius     = 30
# gridElemOffset = 18
# arrowOffset    = gridElemOffset + 2

# nodeSelectionBorderMaxSize = 40

# nodew = 300
# nodeh = 700

# white          = Color.rgb [1,1,1]
# bg             = (Color.hsl [40,0.08,0.09]).toRGB()
# selectionColor = bg.mix (Color.hsl [50, 1, 0.6]), 0.8
# nodeBg         = bg.mix white, 0.04

# normalNode = eval basegl.localExpr (border=0) ->
#   bodyWidth    = 300
#   bodyHeight   = 600
#   slope        = 20
#   headerOffset = arrowOffset
#   r1    = nodeRadius + border
#   r2    = nodeRadius + headerOffset + slope - border
#   dy    = slope
#   dx    = M.sqrt ((r1+r2)*(r1+r2) - dy*dy)
#   angle = M.atan(dy/dx)

#   maskPlane     = glslShape("-sdf_halfplane(p, vec2(1.0,0.0));").moveX(dx)
#   maskRect      = rect(r1+r2, r2 * M.cos(-angle)).alignedTL.rotate(-angle)
#   mask          = (maskRect - maskPlane).inside
#   headerShape   = (circle(r1) + mask) - circle(r2).move(dx,dy)
#   headerFill    = rect(r1*2, nodeRadius + headerOffset + 10).alignedTL.moveX(-r1)
#   header        = (headerShape + headerFill).move(nodeRadius,nodeRadius).moveY(headerOffset+bodyHeight)

#   body          = rect(bodyWidth + 2*border, bodyHeight + 2*border, 0, nodeRadius).alignedBL
#   node          = (header + body).move(nodeSelectionBorderMaxSize,nodeSelectionBorderMaxSize)
#   node          = node.fill nodeBg

#   eye           = 'scaledEye.z'
#   border        = node.grow(M.pow(M.clamp(eye*20.0, 0.0, 400.0),0.7)).grow(-1)

#   sc            = selectionColor.copy()
#   sc.a = 'selected'
#   border        = border.fill sc

#   border + node

# nodeShape = normalNode()




# ### Utils ###

# makeDraggable = (a) ->
#   a.addEventListener 'mousedown', (e) ->
#     if e.button != 0 then return
#     symbol = e.symbol
#     s          = world.activeScene
#     fmove = (e) ->
#       symbol.position.x += e.movementX * s.camera.zoomFactor
#       symbol.position.y -= e.movementY * s.camera.zoomFactor
#     window.addEventListener 'mousemove', fmove
#     window.addEventListener 'mouseup', () =>
#       window.removeEventListener 'mousemove', fmove

# applySelectAnimation = (symbol, rev=false) ->
#   if symbol.selectionAnimation?
#   then symbol.selectionAnimation.reverse()
#   else
#     anim = Animation.create
#       easing      : Easing.quadInOut
#       duration    : 0.1
#       onUpdate    : (v) -> symbol.variables.selected = v
#       onCompleted :     -> delete symbol.selectionAnimation
#     if rev then anim.inverse()
#     anim.start()
#     symbol.selectionAnimation = anim
#     anim

# selectedComponent = null
# makeSelectable = (a) ->
#   a.addEventListener 'mousedown', (e) ->
#     if e.button != 0 then return
#     symbol = e.symbol
#     if selectedComponent == symbol then return
#     applySelectAnimation symbol
#     if selectedComponent
#       applySelectAnimation selectedComponent, true
#       selectedComponent.variables.zIndex = 1
#     selectedComponent = symbol
#     selectedComponent.variables.zIndex = -10




# ### Testing ###


# myShapeF = eval basegl.localExpr () ->
# myShapeF = eval basegl.localExpr () ->
#   base    = circle('myVar')
#   base.fill(Color.rgb [0,0,0,0.7]).move(200,200)
# #
# # myShapeF = eval basegl.localExpr () ->
# #   base = Shape.unionRound 16, circle(100), circle(100).moveX(160), circle(100).move(80,80), circle(100).move(80,-80)
# #   border = base - base.shrink(16)
# #   border.fill(Color.rgb [0,0,0,1]).move(170,250)

# myShape = myShapeF()
myShape = circle('myVar')


export install = (name) ->
  scene = basegl.scene {domElement: name}

  mySymbol  = basegl.symbol myShape
  mySymbol.globalVariables.myVar = 100
  mySymbol1 = scene.add mySymbol

main = () ->
  install 'basegl-root'

# exports

# export {install}
#   #
#   # return

#   #
#   #
#   # myComponent1 = scene.add myComponentDef
#   # myComponent1.position.xy = [0,0]
#   #
#   # myComponent2 = scene.add myComponentDef
#   # myComponent2.position.xy = [0,300]
#   # myComponent2.variables.piotrus = 30
#   #
#   # controls = new Navigator scene
#   #
#   # myComps = group [myComponent1, myComponent2]
#   # myComps.position.x += 100
#   #
#   # # for i in [0..1000]
#   # #   myC = scene.add myComponentDef
#   # #   myC.position.xy = [i * 100,300]
#   # #   myC.variables.piotrus = 30
#   #
#   # # scene.camera.position.z = 10 ## FIXME: czemu nadpisujemy?
#   # # c2 = c.grow(-eye*10) - c ## blad parsowania minusow
#   # # TODO: mouseenter
#   # TODO: post processor
#   #
#   # myComponent2.variables.pointerEvents = 1
#   # myComponent2.style.childrenPointerEvents = POINTER_EVENTS.DISABLED
#   #
#   # makeDraggable myComponent2
#   #
#   #
#   # myComponent2.addEventListener 'mouseover', (e) ->
#   #   console.log "OVER NODE 1!"
#   #
#   # window.navi = controls
#   #
#   #
#   # return



























#   controls = new Navigator scene

#   fontManager = new Font.FontManager null # FIME remove null
#   atlas = fontManager.load
#     fontFamily : 'fonts/DejaVuSansMono.ttf'
#     size       : 2048
#   await atlas.ready
#   atlas.loadGlyphs [32..126]






#   nodeDef = basegl.symbol nodeShape
#   nodeDef.variables.selected = 0
#   nodeDef.bbox.xy = [nodew + 2*nodeSelectionBorderMaxSize, nodeh + 2*nodeSelectionBorderMaxSize]

# # https://www.shadertoy.com/view/4dsSzs ->
# # https://www.shadertoy.com/view/XssXzs#
# # https://www.shadertoy.com/view/XlcSR4


#   n1 = scene.add nodeDef
#   n1.position.xy = [0, 0]
#   n1.id = 1

#   n2 = scene.add nodeDef
#   n2.position.xy = [200, 0]
#   n2.id = 2

#   n3 = scene.add nodeDef
#   n3.position.xy = [400, 0]
#   n3.id = 3

#   str = 'The quick brown fox \njumps over the lazy dog'
#   txt = atlas.addText scene, str
#   txt.position.x += 100
#   txt.position.y += 100

#   n1.variables.pointerEvents = 1
#   n2.variables.pointerEvents = 1
#   n3.variables.pointerEvents = 1

#   n1.variables.zIndex = 1
#   n2.variables.zIndex = 1
#   n3.variables.zIndex = 1

#   n1.addEventListener 'mouseover', (e) ->
#     console.log "OVER NODE 1!"

#   n2.addEventListener 'mouseover', (e) ->
#     console.log "OVER NODE 2!"

#   n3.addEventListener 'mouseover', (e) ->
#     console.log "OVER NODE 3!"


#   n1.addEventListener 'mouseout', (e) ->
#     console.log "OUT NODE 1!"

#   n2.addEventListener 'mouseout', (e) ->
#     console.log "OUT NODE 2!"

#   n3.addEventListener 'mouseout', (e) ->
#     console.log "OUT NODE 3!"

#   n1.style.childrenPointerEvents = POINTER_EVENTS.DISABLED

#   makeDraggable n1
#   makeDraggable n2
#   makeDraggable n3

#   makeSelectable n1
#   makeSelectable n2
#   makeSelectable n3

#   # g1 = group [n1,n2,n3]
#   # g1.position.x += 0

#   # inst = 100000
#   # for i in [0..(Math.sqrt inst)]
#   #   for j in [0..(Math.sqrt inst)]
#   #     n = scene.add node
#   #     n.position.xy = [i*600,j*800]
#   #     n.xxx = [i,j]
#   #     makeDraggable n
#   #
#   #     # msg = "OVER NODE (#{i}, #{j})!"
#   #     n.addEventListener 'mouseover', (e) ->
#   #       console.log e.symbol.xxx

#   # for i in [0..100]
#   #   localComponent = new Component (selectionShape())
#   #   localComponent.bbox.xy = [200,200]
#   #   localComponent1 = scene.add localComponent
#   #   localComponent1.position.xy = [i*100,0]

#   #
#   # selector = new BoxSelector scene, selector
#   # selector.widget.variables.zIndex = 10










# # console.log @_IDBuffer[4*(@width*(@height-@screenMouse.y) + @screenMouse.x)]




# if Detector.webgl
window.run = main
window.run1 = install
# else
#   warning = Detector.getWebGLErrorMessage()
#   alert "WebGL not supported. #{warning}"

# # ns = group [n1,n2]
# # ns.rotation.z = 45
# #










# #
# # ################################
# # ########## HS LOADING ##########
# # ################################
# #
# #
# # ajaxGetAsync = (url) ->
# #   return new Promise (resolve, reject) ->
# #     xhr = new XMLHttpRequest
# #     xhr.timeout = 5000
# #     xhr.onreadystatechange = (evt) ->
# #       if (xhr.readyState == 4)
# #         if(xhr.status == 200) then resolve xhr.responseText else reject (throw new Error xhr.statusText)
# #     xhr.addEventListener "error", reject
# #     xhr.open 'GET', url, true
# #     xhr.send null
# #
# #
# # fileNames = ['rts.js', 'lib.js', 'out.js', 'runmain.js']
# # loader    = Promise.map fileNames, (fileName) -> return ajaxGetAsync fileName
# # loader.catch (e) -> console.log "ERROR loading scripts!"
# # loader.then (srcs) ->
# #     modulesReveal = ("var #{m} = __shared__.modules.#{m};" for m of __shared__.modules).join ''
# #     srcs.unshift modulesReveal
# #     src = srcs.join '\n'
# #     fn = new Function src
# #     fn()
