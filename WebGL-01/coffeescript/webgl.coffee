r = exports ? this

# Ini adalah WebGL context yang digunakan untuk rendering
gl = null

# Mendeteksi WebGL dengan membuat context
r.getWebGLContext = () ->
  window.document.title="Contoh WebGL 01: Menginisialisasi WebGL Context"
  # Mencari canvas untuk digambar
  canvas = document.getElementById "webgl-canvas"
  # Jika tidak ada canvas keluarkan pesan galat
  if canvas == null
    window.alert "Tidak ada canvas di halaman ini"
    return
  
  ##
  # Ini adalah nama-nama context yang bisa didapatkan dari masing-masing
  # browser
  # webgl               - context generik standar w3c
  # experimental-webgl  - context generik standar w3c di beberapa browser
  #                       yang implementasinya masih eksperimental
  # webkit-3d           - context 3d WebKit
  # moz-webgl           - context WebGL untuk mozilla
  ##
  names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"]
  
  # Iterasi dan coba membuat WebGL context dari nama-nama di atas
  for name in names
    try
      gl = canvas.getContext(name)
    catch error
      continue

    break if gl

  # Keluarkan pesan ada tidaknya WebGL
  if gl == null
    window.alert "WebGL tidak tersedia di Browser anda"
  else
    window.alert "WebGL tersedia di Browser Anda"
