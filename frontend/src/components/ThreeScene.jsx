// Three.js 3D Branch Deposits Visualization
// Renders 5 animated 3D bars (one per GTA branch) inside a dark canvas.
// Heights are proportional to branch deposit totals.
// The scene rotates slowly — looks great on the Yoga 7i display.

import { useEffect, useRef } from 'react'
import * as THREE from 'three'

const BRANCHES = [
  { name: 'Downtown TO', deposits: 820000, color: 0xff3b00 },
  { name: 'Scarborough',  deposits: 340000, color: 0xffa500 },
  { name: 'Mississauga',  deposits: 510000, color: 0xffe500 },
  { name: 'Brampton',     deposits: 290000, color: 0xff6b35 },
  { name: 'North York',   deposits: 450000, color: 0xffcc00 },
]

const MAX_DEP = Math.max(...BRANCHES.map(b => b.deposits))

export default function ThreeScene() {
  const mountRef = useRef(null)

  useEffect(() => {
    const mount = mountRef.current
    const W = mount.clientWidth
    const H = mount.clientHeight

    // ── Renderer ──
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
    renderer.setSize(W, H)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    renderer.setClearColor(0x1a1a1a, 1)
    mount.appendChild(renderer.domElement)

    // ── Scene & Camera ──
    const scene  = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(45, W / H, 0.1, 100)
    camera.position.set(0, 5, 12)
    camera.lookAt(0, 1, 0)

    // ── Fog ──
    scene.fog = new THREE.FogExp2(0x1a1a1a, 0.055)

    // ── Lights ──
    scene.add(new THREE.AmbientLight(0xffffff, 0.4))
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8)
    dirLight.position.set(5, 8, 5)
    scene.add(dirLight)

    // ── Base plane grid ──
    const gridHelper = new THREE.GridHelper(14, 14, 0x333333, 0x2a2a2a)
    scene.add(gridHelper)

    // ── Build bars ──
    const group = new THREE.Group()
    const barSpacing = 2.4
    const totalWidth  = (BRANCHES.length - 1) * barSpacing
    const labels = []

    BRANCHES.forEach((branch, i) => {
      const heightNorm = (branch.deposits / MAX_DEP) * 4.5
      const x = i * barSpacing - totalWidth / 2

      // Main bar
      const geo  = new THREE.BoxGeometry(1.4, heightNorm, 1.4)
      const mat  = new THREE.MeshStandardMaterial({
        color: branch.color,
        roughness: 0.3,
        metalness: 0.1,
      })
      const bar = new THREE.Mesh(geo, mat)
      bar.position.set(x, heightNorm / 2, 0)
      group.add(bar)

      // Glowing top cap
      const capGeo = new THREE.BoxGeometry(1.42, 0.06, 1.42)
      const capMat = new THREE.MeshStandardMaterial({
        color: branch.color,
        emissive: branch.color,
        emissiveIntensity: 0.8,
        roughness: 0,
      })
      const cap = new THREE.Mesh(capGeo, capMat)
      cap.position.set(x, heightNorm + 0.03, 0)
      group.add(cap)

      // Floating value sprite (canvas texture)
      const canvas  = document.createElement('canvas')
      canvas.width  = 256
      canvas.height = 96
      const ctx = canvas.getContext('2d')
      ctx.fillStyle = 'rgba(0,0,0,0)'
      ctx.clearRect(0, 0, 256, 96)

      // Amount label
      ctx.font = 'bold 32px Inter, sans-serif'
      ctx.fillStyle = '#ffffff'
      ctx.textAlign = 'center'
      const fmt = (branch.deposits / 1000).toFixed(0) + 'K'
      ctx.fillText('$' + fmt, 128, 36)

      // Branch name
      ctx.font = '500 22px Inter, sans-serif'
      ctx.fillStyle = 'rgba(255,255,255,0.5)'
      ctx.fillText(branch.name, 128, 64)

      const tex     = new THREE.CanvasTexture(canvas)
      const spriteMat = new THREE.SpriteMaterial({ map: tex, transparent: true })
      const sprite  = new THREE.Sprite(spriteMat)
      sprite.position.set(x, heightNorm + 1.2, 0)
      sprite.scale.set(2.4, 0.9, 1)
      group.add(sprite)

      labels.push({ sprite, baseY: heightNorm + 1.2 })
    })

    scene.add(group)

    // ── Animation ──
    let frame
    let t = 0
    const animate = () => {
      frame = requestAnimationFrame(animate)
      t += 0.008

      // Slow rotate
      group.rotation.y = Math.sin(t * 0.4) * 0.35

      // Gentle float on labels
      labels.forEach(({ sprite, baseY }, idx) => {
        sprite.position.y = baseY + Math.sin(t + idx * 1.2) * 0.08
      })

      renderer.render(scene, camera)
    }
    animate()

    // ── Resize ──
    const onResize = () => {
      const w = mount.clientWidth
      const h = mount.clientHeight
      camera.aspect = w / h
      camera.updateProjectionMatrix()
      renderer.setSize(w, h)
    }
    window.addEventListener('resize', onResize)

    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('resize', onResize)
      mount.removeChild(renderer.domElement)
      renderer.dispose()
    }
  }, [])

  return (
    <div className="w-full h-full" ref={mountRef} />
  )
}
