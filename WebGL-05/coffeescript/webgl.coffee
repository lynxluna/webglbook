r = exports ? this

pyraVBO = null
pyraColorVBO = null
cubeVBO = null
cubeColorVBO = null
cubeIBO = null

rotCube = 0.0
rotPyra = 0.0

# Matrix ModelView dan Projection
mvMatrix = mat4.create()
pMatrix  = mat4.create()

# Matrix Stack Management
mvMatrixStack = []

mvMatrixPush = ->
  copy = mat4.create()
  mat4.set mvMatrix, copy
  mvMatrixStack.push copy

mvMatrixPop = ->
  throw "Invalid popMatrix" if mvMatrixStack.length == 0
  mvMatrix = mvMatrixStack.pop()

# Animate Function
animate = () ->
  timeNow = new Date().getTime()
  if animate.lastTime? and animate.lastTime != 0
    elapsed = timeNow - animate.lastTime
    rotCube += (90.0 * elapsed) * 0.001
    rotPyra += (75.0 * elapsed) * 0.001

    rotCube -= 360.0 if rotCube > 360.0
    rotPyra -= 360 if rotPyra > 360.0
  animate.lastTime = timeNow

# Shader Program
shaderProgram = null

# Fungsi CreateShader, membuat shader dari string
createShader = (gl, source, type) ->
  shader = gl.createShader type
  gl.shaderSource shader, source
  gl.compileShader shader
  return shader

# Inisialisasi Shader
initShaders = (gl) ->
  # Fragment shader
  frag = """
  precision mediump float;
  varying   vec4 vertexColor;

  void main(void) {
    // Set Warna Fragment menjadi sama dengan vertexColor
    gl_FragColor = vertexColor;
  }
  """

  # Vertex Shader
  vert = """
  attribute vec3 position; // attribute position
  attribute vec4 color;    // vertex color

  uniform mat4   modelViewMatrix; // modelview Matrix uniform
  uniform mat4   projectionMatrix; // projection matrix uniform

  varying vec4   vertexColor;

  void main(void) {
    // Posisi Akhir = proj * mv * position
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    // Transfer vertex color ke fragment shader
    vertexColor = color;
  }
  """

  # buat Vertex dan Fragment Shader
  fragmentShader = createShader gl, frag, gl.FRAGMENT_SHADER
  vertexShader   = createShader gl, vert, gl.VERTEX_SHADER

  # buat shader program dengan vertex dan fragment shader
  # yang sudah dibuat sebelumnya
  shaderProgram = gl.createProgram()
  gl.attachShader shaderProgram, vertexShader
  gl.attachShader shaderProgram, fragmentShader
  gl.linkProgram  shaderProgram

  # deteksi kesalahan kompilasi shader
  if not gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
    window.alert "Shader Error!"

  # pakai program
  gl.useProgram shaderProgram

  # cari id untuk attribute 'position'
  shaderProgram.positionAttr = gl.getAttribLocation shaderProgram, "position"
  # aktifkan attribute 'position'
  gl.enableVertexAttribArray shaderProgram.positionAttr

  # cari id untuk attribute 'color'
  shaderProgram.colorAttr    = gl.getAttribLocation shaderProgram, "color"
  # aktifkan attribute 'color'
  gl.enableVertexAttribArray shaderProgram.colorAttr

  # cari id untuk uniform 'projectionMatrix'
  shaderProgram.projectionMatrixU =
    gl.getUniformLocation shaderProgram, "projectionMatrix"
  # cari id untuk uniform 'modelViowMatrix'
  shaderProgram.mvMatrixU =
    gl.getUniformLocation shaderProgram, "modelViewMatrix"

# Digunakan untuk memasukkan nilai matrix baru
setMatrixUniforms = (gl) ->
  # Set Uniform Matrix dengan nilai baru
  gl.uniformMatrix4fv shaderProgram.projectionMatrixU, false, pMatrix
  gl.uniformMatrix4fv shaderProgram.mvMatrixU, false, mvMatrix

# Inisialisasi buffer untuk segitiga maupun kotak
initBuffers = (gl) ->

  # Buat VBO untuk Piramid
  pyraVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, pyraVBO
  vertices = [
        # Front face
         0.0,  1.0,  0.0,
        -1.0, -1.0,  1.0,
         1.0, -1.0,  1.0,
        # Right face
         0.0,  1.0,  0.0,
         1.0, -1.0,  1.0,
         1.0, -1.0, -1.0,
        # Back face
        0.0,  1.0,  0.0,
         1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0,
        # Left face
         0.0,  1.0,  0.0,
        -1.0, -1.0, -1.0,
        -1.0, -1.0,  1.0
  ]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  pyraVBO.itemSize = 3
  pyraVBO.numItems = vertices.length / pyraVBO.itemSize

  pyraColorVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, pyraColorVBO
  colors = [
        # Front face
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        # Right face
        1.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        # Back face
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        # Left face
        1.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0
  ]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW
  pyraColorVBO.itemSize = 4
  pyraColorVBO.numItems = 12
  
  # Buat VBO untuk kubus
  cubeVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, cubeVBO
  vertices = [
      # Front face
      -1.0, -1.0,  1.0,
       1.0, -1.0,  1.0,
       1.0,  1.0,  1.0,
      -1.0,  1.0,  1.0,

      # Back face
      -1.0, -1.0, -1.0,
      -1.0,  1.0, -1.0,
       1.0,  1.0, -1.0,
       1.0, -1.0, -1.0,

      # Top face
      -1.0,  1.0, -1.0,
      -1.0,  1.0,  1.0,
       1.0,  1.0,  1.0,
       1.0,  1.0, -1.0,

      # Bottom face
      -1.0, -1.0, -1.0,
       1.0, -1.0, -1.0,
       1.0, -1.0,  1.0,
      -1.0, -1.0,  1.0,

      # Right face
       1.0, -1.0, -1.0,
       1.0,  1.0, -1.0,
       1.0,  1.0,  1.0,
       1.0, -1.0,  1.0,

      # Left face
      -1.0, -1.0, -1.0,
      -1.0, -1.0,  1.0,
      -1.0,  1.0,  1.0,
      -1.0,  1.0, -1.0,
  ]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  cubeVBO.itemSize = 3
  cubeVBO.numItems = 24

  cubeColorVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, cubeColorVBO
  colors = [
    [1.0, 0.0, 0.0, 1.0],     # Front face
    [1.0, 1.0, 0.0, 1.0],     # Back face
    [0.0, 1.0, 0.0, 1.0],     # Top face
    [1.0, 0.5, 0.5, 1.0],     # Bottom face
    [1.0, 0.0, 1.0, 1.0],     # Right face
    [0.0, 0.0, 1.0, 1.0],     # Left face
  ]
  unpackedColors = []
  for color in colors
    for i in [0..3]
      unpackedColors = unpackedColors.concat color

  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(unpackedColors), gl.STATIC_DRAW
  cubeColorVBO.itemSize = 4
  cubeColorVBO.numSize  = 24
  
  # Buat Element Array Buffer / Index Buffer
  cubeIBO = gl.createBuffer()
  gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, cubeIBO
  cubeIndices = [
    0, 1, 2,      0, 2, 3,
    4, 5, 6,      4, 6, 7,
    8, 9, 10,     8, 10, 11,
    12, 13, 14,   12, 14, 15,
    16, 17, 18,   16, 18, 19,
    20, 21, 22,   20, 22, 23
  ]
  gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(cubeIndices), gl.STATIC_DRAW
  cubeIBO.itemSize = 1
  cubeIBO.numItems = 36

degToRad = (deg) ->
  deg * Math.PI / 180.0

# Menggambar layar
drawScene = (gl) ->
  # Bersihkan Scene, Set Viewport, dan Matrix Perspektif
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
  gl.viewport 0, 0, gl.viewportWidth, gl.viewportHeight
  mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix
  mat4.identity mvMatrix

  # Geser -1.5 unit ke kiri dan 7 unit ke dalam
  mat4.translate mvMatrix, [-1.5, 0.0, -7.0]

  # Simpan Matrix lama dan rotasi
  mvMatrixPush()
  mat4.rotate mvMatrix, degToRad(rotPyra), [0, 1, 0]

  # Gambar Piramid
  gl.bindBuffer gl.ARRAY_BUFFER, pyraVBO
  gl.vertexAttribPointer shaderProgram.positionAttr, pyraVBO.itemSize,
    gl.FLOAT, false, 0, 0
  setMatrixUniforms gl

  gl.bindBuffer gl.ARRAY_BUFFER, pyraColorVBO
  gl.vertexAttribPointer shaderProgram.colorAttr, pyraColorVBO.itemSize,
    gl.FLOAT, false, 0, 0

  gl.drawArrays gl.TRIANGLES, 0, pyraVBO.numItems

  # Pakai Matrix lama
  mvMatrixPop()

  # Geser 3 unit ke kanan dari posisi semula
  mat4.translate mvMatrix, [3.0, 0.0, 0.0]

  # Simpan Matrix lama dan rotasi
  mvMatrixPush()
  mat4.rotate mvMatrix, degToRad(rotCube), [1, 1, 1]

  # Gambar kubus dengan index buffer
  gl.bindBuffer gl.ARRAY_BUFFER, cubeVBO
  gl.vertexAttribPointer shaderProgram.positionAttr, cubeVBO.itemSize,
    gl.FLOAT, false, 0, 0
  setMatrixUniforms gl

  gl.bindBuffer gl.ARRAY_BUFFER, cubeColorVBO
  gl.vertexAttribPointer shaderProgram.colorAttr, cubeColorVBO.itemSize,
    gl.FLOAT, false, 0, 0

  gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, cubeIBO
  gl.drawElements gl.TRIANGLES, cubeIBO.numItems, gl.UNSIGNED_SHORT, 0


  # Pakai lagi Matrix lama
  mvMatrixPop()

# Update Function

update = (gl) ->
  window.requestAnimationFrame(update.bind(null, gl))
  drawScene gl
  animate()


# Buat WebGL Context dari Canvas
initContext = (canvasId) ->
  canvas = document.getElementById canvasId
  if null == canvas
    window.alert "Tidak ada canvas di halaman ini"
    return

  names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"]
  for name in names
    try
      gl = canvas.getContext name
    catch error
      continue

    if gl
      gl.viewportWidth = canvas.width
      gl.viewportHeight = canvas.height
      return gl

  return null

# Starting WebGL Scene
r.startWebGL = () ->
  window.document.title = "Contoh WebGL 05: Menambahkan Warna"
  gl = initContext "webgl-canvas"
  if gl == null 
    return
  initShaders gl
  initBuffers gl
  gl.clearColor 0.0, 0.0, 0.0, 1.0
  # Aktifkan DEPTH TEST
  gl.enable gl.DEPTH_TEST

  update gl
