r = exports ? this

# Triangle dan Square VBO
# Buffer dalam GPU yang menyimpan vertex segitiga dan kotak
triangleVBO = null
squareVBO   = null
# Buffer untuk menyimpan warna
triangleColorBuffer = null
squareColorBuffer   = null

# Matrix ModelView dan Projection
mvMatrix = mat4.create()
pMatrix  = mat4.create()

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
  # Buat Buffer untuk segitiga
  #
  #                         (0,1,0)
  #                            /\
  #                           /  \
  #                          /    \
  #                         /      \
  #                        /        \
  #                       /          \
  #           (-1, -1, 0) ------------ (1, -1, 0)
  #
  triangleVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, triangleVBO
  vertices = [ 0.0, 1.0, 0.0,
              -1.0,-1.0, 0.0,
               1.0,-1.0, 0.0 ]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  triangleVBO.itemSize = 3
  triangleVBO.numItems = 3
  
  # Buat buffer untuk kotak
  #
  #        (-1, 1, 0) ---------- (1, 1, 0)
  #                  |\         |
  #                  |  \       |
  #                  |    \     |
  #                  |      \   |
  #                  |        \ |
  #       (-1, -1, 0) ---------- (1, -1, 0)
  #                  
  squareVBO = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, squareVBO
  vertices = [ 1.0, 1.0, 0.0,
              -1.0, 1.0, 0.0,
               1.0,-1.0, 0.0,
              -1.0,-1.0, 0.0]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW
  squareVBO.itemSize = 3
  squareVBO.numItems = 4

  # Warna untuk segitiga
  triangleColorBuffer = gl.createBuffer()
  colors = [
    1.0, 0.0, 0.0, 1.0, # Merah
    0.0, 1.0, 0.0, 1.0, # Hijau
    0.0, 0.0, 1.0, 1.0  # Biru
  ]
  gl.bindBuffer gl.ARRAY_BUFFER, triangleColorBuffer
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW
  triangleColorBuffer.itemSize = 4
  triangleColorBuffer.numItems = 3
  
  # Warna untuk kotak
  squareColorBuffer = gl.createBuffer()
  colors = []
  for i in [1..4]
    colors = colors.concat([0.5, 0.5, 1.0, 1.0])
  gl.bindBuffer gl.ARRAY_BUFFER, squareColorBuffer
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW
  squareColorBuffer.itemSize = 4
  squareColorBuffer.numItems = 4

# Menggambar layar
drawScene = (gl) ->
  # Bersihkan Scene, Set Viewport, dan Matrix Perspektif
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
  gl.viewport 0, 0, gl.viewportWidth, gl.viewportHeight
  mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix
  mat4.identity mvMatrix
  
  # Geser -1.5 unit ke kiri dan 7 unit ke dalam
  mat4.translate mvMatrix, [-1.5, 0.0, -7.0]
  
  # Gambar segitiga
  gl.bindBuffer gl.ARRAY_BUFFER, triangleVBO
  gl.vertexAttribPointer shaderProgram.positionAttr, triangleVBO.itemSize,
    gl.FLOAT, false, 0, 0
  setMatrixUniforms gl
  
  gl.bindBuffer gl.ARRAY_BUFFER, triangleColorBuffer
  gl.vertexAttribPointer shaderProgram.colorAttr, triangleColorBuffer.itemSize,
    gl.FLOAT, false, 0, 0

  gl.drawArrays gl.TRIANGLES, 0, triangleVBO.numItems
  
  # Geser 3 unit ke kanan dari posisi semula
  mat4.translate mvMatrix, [3.0, 0.0, 0.0]
  
  # Gambar kotak
  gl.bindBuffer gl.ARRAY_BUFFER, squareVBO
  gl.vertexAttribPointer shaderProgram.positionAttr, squareVBO.itemSize,
    gl.FLOAT, false, 0, 0
  setMatrixUniforms gl
  
  gl.bindBuffer gl.ARRAY_BUFFER, squareColorBuffer
  gl.vertexAttribPointer shaderProgram.colorAttr, squareColorBuffer.itemSize,
    gl.FLOAT, false, 0, 0

  gl.drawArrays gl.TRIANGLE_STRIP, 0, squareVBO.numItems

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

r.startWebGL = () ->
  window.document.title = "Contoh WebGL 02: Menggambar Kotak dan Segitiga"
  gl = initContext "webgl-canvas"
  if gl == null 
    return
  initShaders gl
  initBuffers gl
  gl.clearColor 0.0, 0.0, 0.0, 1.0

  drawScene gl
