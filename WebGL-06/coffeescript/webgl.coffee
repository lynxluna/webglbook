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
r.startWebGL = () ->
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
  loadFile "js/models/sunfashi.json",
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
  
  # Vertex Shader
  vert = """
  attribute vec3 position;
  
  uniform mat4 modelViewMatrix;
  uniform mat4 projectionMatrix;

  void main(void) {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }  
  """
  
  # Fragment Shader
  frag = """
  precision mediump float;
  uniform vec3 meshColor;

  void main(void) {
    gl_FragColor = vec4(meshColor, 1.0);
  }
  """
  
  # Daftar Attribute dan Uniform
  attributes = ['position']
  uniforms   = ['modelViewMatrix','projectionMatrix', 'meshColor']
  
  # Buat Shader Program
  shaderProgram = createShaderProgram gl, vert, frag, attributes, uniforms
  
  # Aktifkan program
  gl.useProgram shaderProgram.program
  
  # Fungsi animate () untuk mengupdate scene
  animate = () ->
    timeNow = new Date().getTime()
    if animate.lastTime? and animate.lastTime != 0
      elapsed = timeNow - animate.lastTime
    animate.lastTime = timeNow
  
  # Render mesh
  render  = (program, vertbuf, indexbuf, gl) ->
    gl.clear gl.COLOR_BUFFER_BIT
    gl.viewport 0, 0, gl.viewportWidth, gl.viewportHeight
    pMatrix = mat4.create()
    mvMatrix = mat4.create()
    stack = []
    mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix
    mat4.identity mvMatrix
    mat4.translate mvMatrix, [0.0, 0.0 , -13.0]
    
    stack = mvMatrixPush(stack, mvMatrix)
    
    gl.useProgram program.program
    
    gl.bindBuffer gl.ARRAY_BUFFER, vertbuf
    gl.vertexAttribPointer program.attributes['position'],
      vertbuf.elemSize, gl.FLOAT, false, 0, 0
    if indexbuf != null
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, indexbuf

    gl.uniformMatrix4fv program.uniforms["projectionMatrix"],
      false, pMatrix
    gl.uniformMatrix4fv program.uniforms["modelViewMatrix"],
      false, mvMatrix
    if r.meshColor == null
      gl.uniform3fv program.uniforms["meshColor"],
        new Float32Array([0.0, 0, 1.0])
    else
      gl.uniform3fv program.uniforms["meshColor"],
        new Float32Array(r.meshColor)
    
    elem = gl.TRIANGLES
    if window.renderMode == "1"
      elem = gl.LINE_STRIP

    if indexbuf != null
      gl.drawElements elem, indexbuf.numItems, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays   elem, 0, vertbuf.numItems

    stack = mvMatrixPop(stack)
  
  # Update Loop
  update = (gl, renderFunc) ->
    window.requestAnimationFrame(update.bind(null,gl, renderFunc))
    renderFunc(gl)
    animate()
  
  # Set warna dan depth serta aktifkan depth test
  gl.clearColor 0.0, 0.0, 0.233, 1.0
  gl.clearDepth 1.0
  gl.enable gl.DEPTH_TEST

  update(gl, render.bind(null, shaderProgram, vertbuf, indexbuf))

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
    return shader

  program = gl.createProgram()
  gl.attachShader program, createShader(gl, vertexSource, gl.VERTEX_SHADER)
  gl.attachShader program, createShader(gl, fragmentSource, gl.FRAGMENT_SHADER)
  gl.linkProgram program
  if not gl.getProgramParameter(program, gl.LINK_STATUS)
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

loadFile = (url, onComplete) ->
  request = new XMLHttpRequest()
  request.open "GET", url
  request.onreadystatechange = () ->
    if request.readyState == 4
      if (request.status == 200 or (request.status == 0 && document.domain.length == 0))
        onComplete(JSON.parse(request.responseText))
      else
        window.alert("ERROR! XMLHTTP:" + request.status)
  request.send()

