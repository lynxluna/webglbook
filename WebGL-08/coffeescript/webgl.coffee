# Kita membuat program ini dengan pemrograman fungsional
# Tidak ada variabel global dan mutable untuk menghindari kesalahan
# Pemrograman

# r = Window
r = exports ? this

# Deteksi kalau requestAnimationFrame tersedia dalam browser

if not window.requestAnimationFrame?
  if window.webkitRequestAnimationFrame?
    window.requestAnimationFrame = window.webkitRequestAnimationFrame
  else if window.mozRequestAnimationFrame?
    window.requestAnimationFrame = window.mozRequestAnimationFrame
# Entry Point
r.startWebGL = ->
  window.document.title = "WebGL 06: Memuat Model"
  gl = null
  canvas = document.getElementById "webgl-canvas"
  names  = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"]
  for name in names
    try
      gl = canvas.getContext name
      if gl != null
        break
    catch error
      continue

  if gl? and gl == null
    return

  gl.viewportWidth = canvas.width
  gl.viewportHeight = canvas.height
  url = "http://" + document.domain + name 
  loadFile "js/models/ball.json", true,
    handleLoadFile.bind(null, gl)

# Fungsi untuk menangani pemuatan model
# gl: WebGL Context
# model: model data dengan vertex dan index
handleLoadFile = (gl, model) ->
  # Buat Vertex dan Index Buffers
  vertbuf = createBuffer gl, gl.ARRAY_BUFFER, model.vertices, 3
  indexbuf = null
  if model.indices?
    indexbuf = createBuffer gl, gl.ELEMENT_ARRAY_BUFFER, model.indices,
      1, Uint16Array
  normalbuf = createBuffer gl, gl.ARRAY_BUFFER, model.normals, 3
  loadFile "shaders/vert.vsh", false, (vert) -> loadFile "shaders/frag.vsh", false, (frag) -> loadFile "shaders/attruniform.json", true, (au) ->
    
    # Buat Shader Program
    shaderProgram = createShaderProgram gl, vert, frag, 
      au.attributes, au.uniforms
  
    # Aktifkan program
    gl.useProgram shaderProgram.program

    # Set warna dan depth serta aktifkan depth test
    gl.clearColor 0.0, 0.0, 0.233, 1.0
    gl.clearDepth 1.0
    gl.enable gl.DEPTH_TEST

    renderFunc = render.bind(null, shaderProgram, vertbuf, indexbuf, normalbuf)

    update(gl, new Date().getTime() ,renderFunc)
  
  
  # Modified rotation
  rotA = 0.0
  
  # Render mesh
  render  = (program, vertbuf, indexbuf, normalbuf = null, gl, deltaTime) ->
    gl.clear gl.COLOR_BUFFER_BIT
    gl.viewport 0, 0, gl.viewportWidth, gl.viewportHeight
    pMatrix = mat4.create()
    mvMatrix = mat4.create()
    nMatrix = mat4.create()
    lightMVMatrix = mat4.create()

    rotA += deltaTime * 45.0

    stack = []
    mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix
    mat4.identity mvMatrix 
    mat4.translate mvMatrix, [0.0, 0.0 , -4.0]
    mat4.inverse mvMatrix, nMatrix
    mat4.transpose nMatrix, nMatrix

    mat4.identity lightMVMatrix
    mat4.rotate   lightMVMatrix, degToRad(rotA), [0, 1, 0]

    stack = mvMatrixPush(stack, mvMatrix)
    
    gl.useProgram program.program
    
    gl.bindBuffer gl.ARRAY_BUFFER, vertbuf
    gl.vertexAttribPointer program.attributes['position'],
      vertbuf.elemSize, gl.FLOAT, false, 0, 0
    if indexbuf != null
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, indexbuf
    if normalbuf != null
      gl.bindBuffer gl.ARRAY_BUFFER, normalbuf
      gl.vertexAttribPointer program.attributes['normal'],
        normalbuf.elemSize, gl.FLOAT, false, 0, 0

    gl.uniformMatrix4fv program.uniforms["projectionMatrix"],
      false, pMatrix
    gl.uniformMatrix4fv program.uniforms["modelViewMatrix"],
      false, mvMatrix
    gl.uniformMatrix4fv program.uniforms["normalMatrix"],
      false, nMatrix
    gl.uniformMatrix4fv program.uniforms["lightMatrix"],
      false, lightMVMatrix

    gl.uniform3f program.uniforms["lightDirection"], 1.0, 2.0, -1.0
    gl.uniform4fv program.uniforms["materialDiffuse"], new Float32Array(r.meshColor.concat(1.0))
    gl.uniform4f program.uniforms["lightDiffuse"], 1.0, 1.0, 1.0, 1.0
    elem = gl.TRIANGLES
    if window.renderMode == "1"
      elem = gl.LINE_STRIP

    if indexbuf != null
      gl.drawElements elem, indexbuf.numItems, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays   elem, 0, vertbuf.numItems

    stack = mvMatrixPop(stack)
  
  # Update Loop
  update = (gl, lastTime, renderFunc) ->
    currentTime = new Date().getTime()
    deltaTime = (currentTime - lastTime) / 1000.0
    window.requestAnimationFrame(update.bind(null,gl, currentTime, renderFunc))
    renderFunc(gl, deltaTime)
  
  
# Matrix Push
mvMatrixPush = (stack, current) ->
  copy = mat4.create()
  mat4.set current, copy
  newStack = stack.concat(copy)
  return newStack

# Matrix Pop
mvMatrixPop = (stack) ->
  throw "Invalid popMatrix" if stack.length == 0
  return stack.slice(0,-1)

# Buat Shader Program
createShaderProgram = (gl, vertexSource, fragmentSource, attributes, uniforms) ->
  createShader = (gl, shaderSource,shaderType) ->
    shader = gl.createShader shaderType
    gl.shaderSource shader, shaderSource
    gl.compileShader shader
    if not gl.getShaderParameter shader, gl.COMPILE_STATUS
      infoLog = gl.getShaderInfoLog shader
      p = "Unknown Shader"
      if shaderType == gl.VERTEX_SHADER
        p = "Vertex Shader: "
      else if shaderType = gl.FRAGMENT_SHADER
        p = "Fragment Shader: "
      console.log p + infoLog
      return null
    return shader

  program = gl.createProgram()
  gl.attachShader program, createShader(gl, vertexSource, gl.VERTEX_SHADER)
  gl.attachShader program, createShader(gl, fragmentSource, gl.FRAGMENT_SHADER)
  gl.linkProgram program
  if not gl.getProgramParameter(program, gl.LINK_STATUS)
    infoLog = gl.getProgramInfoLog program
    console.log infoLog
    window.alert "Shader Error!"
    return null
  
  # Buat Map berisi program, lokasi attribute, dan lokasi uniform
  rMap = {}
  rMap.program    = program
  rMap.attributes = {}
  rMap.uniforms   = {}

  gl.useProgram(program)
  for attr in attributes
    loc = gl.getAttribLocation program, attr
    rMap.attributes[attr] = loc
    gl.enableVertexAttribArray loc

  for uni in uniforms
    loc = gl.getUniformLocation program, uni
    rMap.uniforms[uni]    = loc

  return rMap

degToRad = (deg) ->
  deg * Math.PI / 180.0

createBuffer = (gl, bufferType, bufferData, elemSize, objType=Float32Array ) ->
  buffer = gl.createBuffer()
  gl.bindBuffer bufferType, buffer
  gl.bufferData bufferType, new objType(bufferData), gl.STATIC_DRAW
  gl.bindBuffer bufferType, null
  
  buffer.elemSize = elemSize
  buffer.numItems = bufferData.length / elemSize
  
  buffer.activate = gl.bindBuffer.bind(null, bufferType, buffer)

  return buffer

loadFile = (url, json=true, onComplete) ->
  request = new XMLHttpRequest()
  request.open "GET", url
  request.onreadystatechange = () ->
    if request.readyState == 4
      if (request.status == 200 or (request.status == 0 && document.domain.length == 0))
        if json
          onComplete(JSON.parse(request.responseText))
        else
          onComplete(request.responseText)
      else
        window.alert("ERROR! XMLHTTP:" + request.status)
  request.send()

