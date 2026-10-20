// NEON NOIR · shader della modalità cinema (template)
// `cinema --<modalità>` antepone a questo file i #define della modalità (vedi cinema.ps1) e genera
// %LOCALAPPDATA%\neon\shaders\<modalità>-<hash>.hlsl, che Windows Terminal carica come pixel shader.
// Ogni parametro ha un valore neutro di default: una modalità imposta solo ciò che le serve.
// Gli effetti "di sfondo" (pioggia, griglia, cielo, stelle) passano dietro al testo grazie alla maschera `ink`.

// ── base ────────────────────────────────────────────────────────────────────
#ifndef CURVE
#define CURVE 0.0                          // curvatura dello schermo (0 = piatto)
#endif
#ifndef GLOW_STRENGTH
#define GLOW_STRENGTH 0.0                  // bagliore attorno al testo
#endif
#ifndef GLOW_SPREAD
#define GLOW_SPREAD 2.0                    // ampiezza del bagliore (px)
#endif
#ifndef SCANLINE_PX
#define SCANLINE_PX 3.0                    // periodo delle scanline (px fisici)
#endif
#ifndef SCANLINE_DIM
#define SCANLINE_DIM 0.0                   // intensità delle scanline
#endif
#ifndef VIGNETTE
#define VIGNETTE 0.0                       // scurimento ai bordi
#endif
#ifndef TINT
#define TINT float3(0.0, 0.0, 0.0)         // velatura aggiunta (colore dei "neri")
#endif
#ifndef CONTRAST
#define CONTRAST 1.0
#endif
#ifndef CHROMA_PX
#define CHROMA_PX 0.0                      // aberrazione cromatica (px)
#endif
#ifndef NOISE
#define NOISE 0.0                          // grana statica
#endif

// ── colore ──────────────────────────────────────────────────────────────────
#ifndef MONO
#define MONO 0.0                           // 0 = colori originali, 1 = monocromatico
#endif
#ifndef MONO_COLOR
#define MONO_COLOR float3(1.0, 1.0, 1.0)   // colore del fosforo in monocromatico
#endif
#ifndef MONO_GAIN
#define MONO_GAIN 1.0
#endif
#ifndef DESAT
#define DESAT 0.0                          // desaturazione che risparmia i rossi (0..1)
#endif
#ifndef GRADE
#define GRADE 0.0                          // color grading ombre/luci (0..1)
#endif
#ifndef SHADOW_TINT
#define SHADOW_TINT float3(1.0, 1.0, 1.0)
#endif
#ifndef HIGHLIGHT_TINT
#define HIGHLIGHT_TINT float3(1.0, 1.0, 1.0)
#endif
#ifndef DUOTONE
#define DUOTONE 0                          // 1 = testo in gradiente a due colori
#endif
#ifndef DUO_LOW
#define DUO_LOW float3(0.4, 0.1, 0.6)
#endif
#ifndef DUO_HIGH
#define DUO_HIGH float3(0.4, 1.0, 1.0)
#endif

// ── effetti animati comuni ──────────────────────────────────────────────────
#ifndef USE_ANIM
#define USE_ANIM 0                         // 1 = banda di scansione che scorre
#endif
#ifndef BAND_SPEED
#define BAND_SPEED 0.06
#endif
#ifndef BAND_JITTER
#define BAND_JITTER 0.0                    // spostamento orizzontale nella banda (px)
#endif
#ifndef BAND_GLOW
#define BAND_GLOW 0.0
#endif
#ifndef BAND_COLOR
#define BAND_COLOR float3(1.0, 1.0, 1.0)
#endif
#ifndef FLICKER
#define FLICKER 0.0                        // sfarfallio (solo con USE_ANIM)
#endif

// ── effetti firma (0/1 + parametri) ─────────────────────────────────────────
#ifndef SHADOW_MASK
#define SHADOW_MASK 0                      // tv: griglia RGB dei fosfori
#endif
#ifndef SHADOW_MASK_AMOUNT
#define SHADOW_MASK_AMOUNT 0.5
#endif
#ifndef BEZEL
#define BEZEL 0                            // tv: cornice arrotondata + riflesso sul vetro
#endif
#ifndef BEZEL_SIZE
#define BEZEL_SIZE 0.025
#endif
#ifndef BEZEL_RADIUS
#define BEZEL_RADIUS 0.05
#endif
#ifndef MATRIX_RAIN
#define MATRIX_RAIN 0                      // matrix: pioggia di codice
#endif
#ifndef RAIN_CELL
#define RAIN_CELL 11.0
#endif
#ifndef RAIN_COLOR
#define RAIN_COLOR float3(0.1, 0.9, 0.35)
#endif
#ifndef RAIN_STRENGTH
#define RAIN_STRENGTH 0.5
#endif
#ifndef PHOSPHOR_TRAIL
#define PHOSPHOR_TRAIL 0                   // amber: persistenza del fosforo
#endif
#ifndef ROLL_BAR
#define ROLL_BAR 0                         // amber: banda scura che scorre (CRT ripreso in video)
#endif
#ifndef ROLL_SPEED
#define ROLL_SPEED 0.035
#endif
#ifndef ROLL_DIM
#define ROLL_DIM 0.14
#endif
#ifndef CRAWL
#define CRAWL 0                            // star-wars: titoli in prospettiva verso l'orizzonte
#endif
#ifndef CRAWL_START
#define CRAWL_START 0.5                    // sotto questa altezza lo schermo resta piatto e leggibile
#endif
#ifndef CRAWL_TILT
#define CRAWL_TILT 0.85                    // inclinazione del piano verso l'alto (0..0.95)
#endif
#ifndef CRAWL_FAR_TINT
#define CRAWL_FAR_TINT float3(1.0, 1.0, 1.0)   // colore del testo in lontananza
#endif
#ifndef STARS
#define STARS 0.0                          // densità del campo stellare
#endif
#ifndef NEBULA
#define NEBULA 0                           // star-wars: nebulosa
#endif
#ifndef NEBULA_COLOR
#define NEBULA_COLOR float3(0.25, 0.12, 0.45)
#endif
#ifndef GLITCH
#define GLITCH 0                           // hologram / mr-robot: fette che saltano + blocchi digitali
#endif
#ifndef GLITCH_SLICES
#define GLITCH_SLICES 28.0
#endif
#ifndef GLITCH_RATE
#define GLITCH_RATE 4.0
#endif
#ifndef GLITCH_AMOUNT
#define GLITCH_AMOUNT 0.05
#endif
#ifndef GLITCH_BLOCKS
#define GLITCH_BLOCKS 0
#endif
#ifndef EDGE_GLOW
#define EDGE_GLOW 0                        // hologram / tron: contorni luminosi
#endif
#ifndef EDGE_COLOR
#define EDGE_COLOR float3(0.3, 0.8, 1.0)
#endif
#ifndef HOLO_BEAM
#define HOLO_BEAM 0                        // hologram: fascio del proiettore dal basso
#endif
#ifndef HOLO_TOP
#define HOLO_TOP 0.6
#endif
#ifndef LETTERBOX
#define LETTERBOX 0                        // blade-runner: barre cinemascope
#endif
#ifndef LETTERBOX_SIZE
#define LETTERBOX_SIZE 0.06
#endif
#ifndef ANAMORPHIC
#define ANAMORPHIC 0                       // blade-runner: riflessi anamorfici orizzontali
#endif
#ifndef ANAMORPHIC_AMOUNT
#define ANAMORPHIC_AMOUNT 0.35
#endif
#ifndef ANAMORPHIC_COLOR
#define ANAMORPHIC_COLOR float3(0.3, 0.55, 1.0)
#endif
#ifndef RAIN_STREAKS
#define RAIN_STREAKS 0                     // blade-runner: pioggia obliqua
#endif
#ifndef RAIN_STREAK_COLOR
#define RAIN_STREAK_COLOR float3(0.18, 0.24, 0.30)
#endif
#ifndef GRID
#define GRID 0                             // tron / synthwave: griglia in prospettiva
#endif
#ifndef GRID_HORIZON
#define GRID_HORIZON 0.62
#endif
#ifndef GRID_DENSITY
#define GRID_DENSITY 6.0
#endif
#ifndef GRID_SPEED
#define GRID_SPEED 0.15
#endif
#ifndef GRID_COLOR
#define GRID_COLOR float3(0.0, 0.6, 0.9)
#endif
#ifndef SKY
#define SKY 0                              // synthwave: cielo al tramonto con sole a strisce
#endif
#ifndef SKY_TOP
#define SKY_TOP float3(0.03, 0.0, 0.08)
#endif
#ifndef SKY_BOTTOM
#define SKY_BOTTOM float3(0.25, 0.03, 0.22)
#endif
#ifndef VHS
#define VHS 0                              // vhs: sbavatura colore, head switching, nastro rovinato
#endif
#ifndef GRAIN_ANIM
#define GRAIN_ANIM 0.0                     // grana animata da pellicola
#endif
#ifndef SCRATCHES
#define SCRATCHES 0                        // noir: graffi verticali e polvere
#endif
#ifndef EXPOSURE_FLICKER
#define EXPOSURE_FLICKER 0.0               // noir: tremolio dell'esposizione
#endif
#ifndef HUD
#define HUD 0                              // terminator: griglia, scansione, mirino
#endif
#ifndef HUD_COLOR
#define HUD_COLOR float3(1.0, 0.15, 0.1)
#endif

// ── effetti firma (seconda parte) ───────────────────────────────────────────
#ifndef SAFE_AREA
#define SAFE_AREA 0.0                      // tv: il contenuto rientra dai bordi (frazione per lato)
#endif
#ifndef CRAWL_SPEED
#define CRAWL_SPEED 0.035                  // star-wars: velocità del crawl (frazioni di schermo al secondo)
#endif
#ifndef CRAWL_GAP
#define CRAWL_GAP 0.30                     // star-wars: spazio vuoto tra una ripetizione e l'altra
#endif
#ifndef TIE
#define TIE 0                              // star-wars: TIE Fighter che attraversano lo spazio e sparano
#endif
#ifndef GALAXY
#define GALAXY 0                           // star-wars: fascia galattica con polvere e stelle fitte
#endif
#ifndef SKYLINE
#define SKYLINE 0                          // blade-runner: palazzi con finestre accese
#endif
#ifndef NEON_HAZE
#define NEON_HAZE 0                        // blade-runner: foschia al neon e spinner nel cielo
#endif
#ifndef READ_PANEL
#define READ_PANEL 0.0                     // attenua gli effetti d'ambiente al centro dello schermo (area di lettura)
#endif
#ifndef EDGE_STRENGTH
#define EDGE_STRENGTH 1.0                  // intensità dei contorni luminosi
#endif
#ifndef GRID_STRENGTH
#define GRID_STRENGTH 1.0                  // intensità della griglia
#endif
#ifndef SEL_FIX
#define SEL_FIX 0                          // testo bianco dentro la selezione (Windows Terminal non ha selectionForeground)
#endif
#ifndef SEL_COLOR
#define SEL_COLOR float3(0.72, 0.08, 0.05) // selectionBackground dello schema
#endif

// ── leggibilità (valgono per tutte le modalità) ─────────────────────────────
#ifndef TEXT_MIN
#define TEXT_MIN 0.50                      // luminosità minima del testo (stessa tinta, più luce)
#endif
#ifndef INK_PROTECT
#define INK_PROTECT 0.75                   // quanto il testo è protetto da scanline, vignettatura, grana, sfarfallio
#endif
#ifndef HALO
#define HALO 0.85                          // alone scuro che separa il testo dagli sfondi animati
#endif

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

float Hash(float2 p) { return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }
float Luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }
// attenua un fattore che scurisce (scanline, vignettatura...) dove c'è testo
float Protect(float mul, float ink) { return lerp(mul, 1.0, ink * INK_PROTECT); }
float3 Tex(float2 uv) { return shaderTexture.Sample(samplerState, saturate(uv)).rgb; }

float Noise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(Hash(i), Hash(i + float2(1, 0)), f.x), lerp(Hash(i + float2(0, 1)), Hash(i + float2(1, 1)), f.x), f.y);
}

float2 Curve(float2 uv)
{
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + (uv.yx * uv.yx) * CURVE;
    return uv * 0.5 + 0.5;
}

// griglia in prospettiva sul "pavimento" sotto l'orizzonte
float GridFloor(float2 tex, float time)
{
    float py = (tex.y - GRID_HORIZON) / (1.0 - GRID_HORIZON);
    float z = 1.0 / max(py, 0.002);
    float2 g = float2((tex.x - 0.5) * z, z + time * GRID_SPEED) * GRID_DENSITY;
    float2 d = abs(frac(g - 0.5) - 0.5) / max(fwidth(g), 1e-4);
    float lineV = 1.0 - min(min(d.x, d.y), 1.0);
    return lineV * saturate(py * 3.0) * step(0.0, py);
}

// TIE Fighter visto di lato: due ali esagonali, braccio e abitacolo sferico (distanze con bordo morbido)
float3 TieFighter(float2 tex, float2 c, float size, float ar)
{
    float2 q = (tex - c) * float2(ar, 1.0) / size;
    float aa = 2.5 / (size * Resolution.y);
    float wing = max(abs(abs(q.x) - 0.92) - 0.07, abs(q.y) - 0.95 + max(0.0, abs(q.x) - 0.92) * 0.0);
    float strut = max(abs(q.x) - 0.86, abs(q.y) - 0.07);
    float r = length(q);
    float pod = r - 0.34;
    float body = saturate(0.5 - min(min(wing, strut), pod) / aa);
    float rim = saturate(0.5 - (abs(r - 0.30) - 0.035) / aa) + saturate(0.5 - (abs(wing) - 0.03) / aa);
    float3 col = lerp(float3(0.16, 0.18, 0.22), float3(0.62, 0.67, 0.75), saturate(rim));
    col = lerp(col, float3(0.03, 0.04, 0.06), saturate(0.5 - (r - 0.15) / aa));
    return col * body;
}

// dardo laser: segmento luminoso che avanza in orizzontale dal caccia
float LaserBolt(float2 tex, float2 head, float dir, float ar)
{
    float2 p = tex * float2(ar, 1.0);
    float2 a = head * float2(ar, 1.0);
    float2 b = (head - float2(dir * 0.035, 0.0)) * float2(ar, 1.0);
    float2 pa = p - a, ba = b - a;
    float dist = length(pa - ba * saturate(dot(pa, ba) / dot(ba, ba)));
    return smoothstep(0.0028, 0.0, dist) + exp(-dist * 260.0) * 0.45;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float2 texel = 1.0 / Resolution;
    float px = max(Scale, 1.0);
    float2 uv = tex;

#if LETTERBOX
    float lbMask = step(LETTERBOX_SIZE, tex.y) * step(tex.y, 1.0 - LETTERBOX_SIZE);
    uv.y = (tex.y - LETTERBOX_SIZE) / (1.0 - 2.0 * LETTERBOX_SIZE);
#endif

    uv = (uv - 0.5) * (1.0 + 2.0 * SAFE_AREA) + 0.5;   // area di sicurezza: il contenuto rientra dai bordi
    uv = Curve(uv);
    float outside = (any(uv < 0.0) || any(uv > 1.0)) ? 1.0 : 0.0;

    float band = 0.0;
#if USE_ANIM
    float b = frac(uv.y - Time * BAND_SPEED);
    band = smoothstep(0.0, 0.03, b) * (1.0 - smoothstep(0.03, 0.07, b));
    uv.x += band * BAND_JITTER * px * texel.x;
#endif

#if CRAWL
    // Sotto CRAWL_START lo schermo resta piatto: è l'area di lavoro (prompt e output recente).
    // Sopra, la parte alta del terminale scorre in continuo su un piano inclinato verso il punto di fuga,
    // centrata sull'asse verticale, rimpicciolendo con la distanza; tra una ripetizione e l'altra c'è
    // uno spazio vuoto (CRAWL_GAP), quindi non ci sono cuciture né salti.
    float crawlT = saturate((CRAWL_START - tex.y) / CRAWL_START);      // 0 al confine, 1 in alto
    float z = 1.0 / max(1.0 - crawlT * CRAWL_TILT, 0.05);
    float dist = (z - 1.0) / CRAWL_TILT * CRAWL_START;                // distanza lungo il piano
    float period = CRAWL_START * (1.0 + CRAWL_GAP);
    float crawlQ = frac((dist - Time * CRAWL_SPEED) / period) * period;   // posizione nel testo che scorre
    float2 crawlUv = float2(0.5 + (tex.x - 0.5) * z, CRAWL_START - crawlQ);
    float inText = step(crawlQ, CRAWL_START) * step(0.0, crawlUv.x) * step(crawlUv.x, 1.0);
    bool inCrawl = tex.y < CRAWL_START;
    uv = inCrawl ? crawlUv : uv;
    float persp = inCrawl ? 1.0 - crawlT : 1.0;                       // 1 = vicino, 0 = lontano
    float crawlMask = inCrawl ? inText * smoothstep(0.0, 0.06, crawlT) * (1.0 - smoothstep(0.62, 0.96, crawlT)) : 1.0;
#endif

    float gOn = 0.0;
#if GLITCH
    // fette orizzontali che saltano di lato a intervalli casuali
    float slice = floor(uv.y * GLITCH_SLICES);
    float tick = floor(Time * GLITCH_RATE);
    gOn = step(1.0 - GLITCH_AMOUNT, Hash(float2(slice, tick)));
    uv.x += (Hash(float2(slice, tick + 7.0)) - 0.5) * 0.04 * gOn;
#endif

    float headZone = 0.0;
#if VHS
    // zona di "head switching" in fondo allo schermo
    headZone = smoothstep(0.975, 1.0, uv.y);
    uv.x += headZone * (Noise(float2(uv.y * 120.0, Time * 30.0)) - 0.5) * 0.03;
#endif

    float4 base = shaderTexture.Sample(samplerState, saturate(uv));
    float3 color = base.rgb;

    float selText = 0.0;
#if SEL_FIX
    // pixel diversi dallo sfondo della selezione ma circondati da esso = testo selezionato
    float2 so = texel * px * 1.5;
    float near = step(distance(Tex(uv + float2(so.x, 0.0)), SEL_COLOR), 0.09) + step(distance(Tex(uv - float2(so.x, 0.0)), SEL_COLOR), 0.09)
               + step(distance(Tex(uv + float2(0.0, so.y)), SEL_COLOR), 0.09) + step(distance(Tex(uv - float2(0.0, so.y)), SEL_COLOR), 0.09);
    selText = saturate(near) * saturate(distance(base.rgb, SEL_COLOR) * 4.0);
#endif

    // aberrazione cromatica (più forte durante i glitch)
    float chroma = CHROMA_PX + gOn * 6.0;
    float2 co = float2(chroma * px * texel.x, 0.0);
    color.r = lerp(color.r, Tex(uv + co).r, chroma > 0.0);
    color.b = lerp(color.b, Tex(uv - co).b, chroma > 0.0);

#if VHS
    // sbavatura del colore: crominanza sfocata in orizzontale, luminanza nitida
    float3 bleed = 0;
    [unroll] for (int k = -3; k <= 3; k++) bleed += Tex(uv + float2(k * 1.0 * px * texel.x, 0.0));
    bleed /= 7.0;
    color = Luma(color) + (bleed - Luma(bleed));
#endif

#if PHOSPHOR_TRAIL
    // persistenza del fosforo: il testo lascia una scia che si spegne verso il basso
    [unroll] for (int t = 1; t <= 4; t++)
        color = max(color, Tex(uv - float2(0.0, t * 1.5 * px * texel.y)) * (0.42 / t));
#endif

    // bagliore: media gaussiana 5x5, solo ciò che è più luminoso dello sfondo
    float3 glow = 0;
    float wsum = 0;
    [unroll] for (int y = -2; y <= 2; y++)
    {
        [unroll] for (int x = -2; x <= 2; x++)
        {
            float w = exp(-(x * x + y * y) / 3.0);
            glow += Tex(uv + float2(x, y) * texel * GLOW_SPREAD * px) * w;
            wsum += w;
        }
    }
    glow /= wsum;
    color += max(glow - Background.rgb, 0) * GLOW_STRENGTH;

#if ANAMORPHIC
    // riflesso anamorfico: strisce orizzontali che partono dalle luci più forti
    float3 streak = 0;
    [unroll] for (int a = 1; a <= 10; a++)
    {
        float2 o = float2(a * 4.0 * px * texel.x, 0.0);
        streak += (max(Tex(uv + o) - Background.rgb, 0) + max(Tex(uv - o) - Background.rgb, 0)) * (1.0 - a / 11.0);
    }
    color += Luma(streak) * ANAMORPHIC_COLOR * ANAMORPHIC_AMOUNT;
#endif

#if EDGE_GLOW
    float2 e = texel * px * 1.5;
    float gx = Luma(Tex(uv + float2(e.x, 0.0))) - Luma(Tex(uv - float2(e.x, 0.0)));
    float gy = Luma(Tex(uv + float2(0.0, e.y))) - Luma(Tex(uv - float2(0.0, e.y)));
    float edge = saturate(length(float2(gx, gy)) * 3.0);
#endif

    // maschera del testo: 1 dove c'è testo, 0 sullo sfondo
    float ink = saturate((Luma(base.rgb) - Luma(Background.rgb)) * 6.0);
    float lum = Luma(color);

    // ── colore ──
    color = lerp(color, lum * MONO_COLOR * MONO_GAIN, MONO);
#if DUOTONE
    color = lerp(DUO_LOW, DUO_HIGH, saturate(lum * 1.4)) * (0.35 + lum * 1.4);
#endif
    float redness = saturate((color.r - max(color.g, color.b)) * 3.0);
    color = lerp(color, lerp(lum.xxx, color, redness), DESAT);
    color = lerp(color, color * lerp(SHADOW_TINT, HIGHLIGHT_TINT, saturate(lum * 1.6)), GRADE);
    color = (color - 0.5) * CONTRAST + 0.5;
#if CRAWL
    color *= lerp(CRAWL_FAR_TINT, float3(1.0, 1.0, 1.0), saturate(persp * 1.3));   // oro vicino, arancio lontano
#endif
#if EDGE_GLOW
    color += edge * EDGE_COLOR * EDGE_STRENGTH;
#endif

    // ── sfondi dietro al testo ──
    float3 bg = 0;
    float3 bgFixed = 0;   // sfondi che il pannello di lettura non attenua (es. lo skyline)
#if SKY
    float horizon = GRID_HORIZON;
    float above = step(tex.y, horizon);
    bg += lerp(SKY_TOP, SKY_BOTTOM, saturate(tex.y / horizon)) * above;
    float2 sp = (tex - float2(0.5, horizon - 0.14)) * float2(Resolution.x / Resolution.y, 1.0);
    float sun = smoothstep(0.172, 0.165, length(sp)) * above;
    float stripes = step(0.42, frac((tex.y - horizon + 0.14) * 34.0 * (1.0 + saturate(sp.y * 6.0))));
    sun *= sp.y < 0.0 ? 1.0 : stripes;
    bg += sun * lerp(float3(1.0, 0.85, 0.30), float3(1.0, 0.18, 0.55), saturate((tex.y - (horizon - 0.32)) / 0.32)) * 0.75;
#endif
#if GRID
    bg += GridFloor(tex, Time) * GRID_COLOR * GRID_STRENGTH;
    bg += exp(-abs(tex.y - GRID_HORIZON) * 140.0) * GRID_COLOR * 0.9 * GRID_STRENGTH;   // linea dell'orizzonte
#endif
#if MATRIX_RAIN
    float cw = RAIN_CELL * px;
    float colId = floor(pos.x / cw);
    float activeCol = step(0.35, Hash(float2(colId, 3.1)));
    float speed = 0.08 + Hash(float2(colId, 1.7)) * 0.18;
    float dist = frac(frac(Time * speed + Hash(float2(colId, 9.2))) - tex.y);   // 0 = testa della goccia
    float trail = pow(saturate(1.0 - dist / 0.45), 2.2);
    float cellY = floor(pos.y / (cw * 1.5));
    float glyph = step(0.3, Hash(float2(colId, cellY + floor(Time * 5.0 + Hash(float2(colId, cellY)) * 20.0))));
    float dots = step(0.45, Hash(floor(pos.xy / (2.0 * px))));
    float inCell = step(frac(pos.x / cw), 0.8) * step(frac(pos.y / (cw * 1.5)), 0.85);
    float rain = activeCol * trail * glyph * dots * inCell;
    bg += rain * lerp(RAIN_COLOR, float3(0.85, 1.0, 0.9), step(dist, 0.012)) * RAIN_STRENGTH;
#endif
#if RAIN_STREAKS
    float2 r = float2(pos.x + pos.y * 0.22, pos.y) / px;
    float rc = floor(r.x / 7.0);
    float rt = frac(r.y / (Resolution.y / px) * 0.9 + Time * (0.9 + Hash(float2(rc, 2.0)) * 0.8) + Hash(float2(rc, 5.0)));
    float drop = step(0.88, Hash(float2(rc, 0.5))) * smoothstep(0.10, 0.0, rt) * (1.0 - saturate(abs(frac(r.x / 7.0) - 0.5) * 7.0));
    bg += drop * RAIN_STREAK_COLOR;
    bg += float3(0.02, 0.05, 0.07) * saturate((tex.y - 0.6) * 2.5);   // foschia al neon in basso
#endif
#if NEBULA
    float neb = Noise(tex * float2(5.0, 3.0) + Time * 0.004) * Noise(tex * 11.0 + 4.0);
    bg += neb * NEBULA_COLOR * saturate(1.2 - tex.y);
#endif
#if GALAXY
    // fascia galattica diagonale: polvere viola/blu e stelle più fitte
    float bandY = 0.20 + (tex.x - 0.5) * 0.26;
    float gBand = exp(-pow((tex.y - bandY) / 0.09, 2.0));
    float dust = Noise(tex * float2(9.0, 5.0) + Time * 0.003) * Noise(tex * 23.0 + 7.0);
    bg += gBand * (0.30 + dust) * float3(0.11, 0.07, 0.18);
    bg += step(1.0 - 0.010 * gBand, Hash(floor(pos.xy / px) + 41.0)) * 0.45 * float3(0.85, 0.90, 1.0);
#endif
#if TIE
    // tre TIE Fighter su traiettorie diverse, ognuno spara due dardi verdi per passaggio
    float ar = Resolution.x / Resolution.y;
    [unroll] for (int f = 0; f < 3; f++)
    {
        float per = 12.0 + f * 3.5;
        float ph = frac(Time / per + f * 0.37);
        float dir = f == 1 ? -1.0 : 1.0;
        float2 c = float2(dir > 0.0 ? lerp(-0.15, 1.15, ph) : lerp(1.15, -0.15, ph), 0.08 + f * 0.105 + 0.012 * sin(Time * 0.9 + f * 2.0));
        float size = 0.030 - f * 0.005;
        bg += TieFighter(tex, c, size, ar);
        [unroll] for (int k = 0; k < 2; k++)
        {
            float bp = frac(Time * 0.8 + f * 0.29 + k * 0.5);
            float2 head = c + float2(dir * (size * 1.2 / ar + bp * 0.45), (k == 0 ? 1.0 : -1.0) * size * 0.25);
            bg += LaserBolt(tex, head, dir, ar) * step(bp, 0.65) * float3(0.30, 1.0, 0.38);
        }
    }
#endif
#if SKYLINE
    // due file di palazzi (lontani e vicini) con finestre accese che cambiano lentamente
    [unroll] for (int layer = 0; layer < 2; layer++)
    {
        float cols = layer == 0 ? 70.0 : 36.0;
        float colB = floor(tex.x * cols + layer * 13.0);
        float hgt = layer == 0 ? 0.12 + Hash(float2(colB, 1.0)) * 0.16 : 0.05 + Hash(float2(colB, 2.0)) * 0.10;
        float inB = step(1.0 - tex.y, hgt);
        float3 wall = layer == 0 ? float3(0.030, 0.040, 0.070) : float3(0.045, 0.055, 0.090);
        float2 w = float2(tex.x * cols * 4.0, pos.y / (5.0 * px));
        float lit = step(0.80, Hash(floor(w) + colB + floor(Time * 0.05 + Hash(floor(w)) * 7.0)));
        float winShape = step(frac(w.x), 0.55) * step(frac(w.y), 0.5);
        float3 winCol = lerp(float3(0.30, 0.17, 0.05), float3(0.05, 0.21, 0.25), step(0.6, Hash(floor(w) + 3.0)));
        bgFixed = lerp(bgFixed, wall + winCol * lit * winShape * (layer == 0 ? 0.55 : 0.85), inB);
    }
#endif
#if NEON_HAZE
    // foschia al neon ai margini (ambra, teal, rosa) e uno spinner che attraversa il cielo
    float2 acH = float2(Resolution.x / Resolution.y, 1.0);
    float pulse = 0.85 + 0.15 * sin(Time * 0.6);
    bg += exp(-length((tex - float2(0.10, 0.95)) * acH) * 3.4) * float3(0.30, 0.13, 0.03) * pulse;
    bg += exp(-length((tex - float2(0.92, 0.82)) * acH) * 3.8) * float3(0.03, 0.19, 0.23);
    bg += exp(-length((tex - float2(0.55, 1.08)) * acH) * 4.2) * float3(0.20, 0.04, 0.13) * (1.1 - pulse * 0.2);
    float spT = frac(Time / 23.0);
    float2 spPos = float2(lerp(-0.1, 1.1, spT), 0.16 + 0.04 * sin(spT * 6.2831853));
    float spD = length((tex - spPos) * acH);
    bg += exp(-spD * 900.0) * float3(1.0, 0.78, 0.45) * 1.4 + exp(-spD * 140.0) * float3(0.22, 0.11, 0.04);
    bg += exp(-length((tex - spPos - float2(0.006, 0.0)) * acH) * 1400.0) * float3(1.0, 0.12, 0.05) * step(0.5, frac(Time * 1.5));
#endif
    float starAmount = STARS;
    if (starAmount > 0.0)
    {
        float2 cell = floor(pos.xy / px);
        float h = Hash(cell);
        float star = step(1.0 - 0.004 * starAmount, h);
        float big = step(1.0 - 0.0006 * starAmount, h);
        float twinkle = 0.55 + 0.45 * sin(Time * (1.0 + Hash(cell + 3.0) * 2.0) + Hash(cell + 17.0) * 6.2831853);
        float3 starColor = lerp(float3(0.75, 0.85, 1.0), float3(1.0, 0.9, 0.7), Hash(cell + 9.0));
        bg += (star * 0.8 + big * 0.6) * twinkle * starColor;
    }

#if CRAWL
    color *= crawlMask;
#endif
    // alone scuro attorno ai caratteri: gli sfondi (pioggia, griglia, cielo, stelle) non coprono mai il testo
    // pannello di lettura: gli effetti d'ambiente si attenuano verso il centro dello schermo
    float2 pm = smoothstep(0.0, 0.16, tex) * smoothstep(0.0, 0.16, 1.0 - tex);
    bg *= 1.0 - READ_PANEL * pm.x * pm.y;
    float halo = saturate((Luma(glow) - Luma(Background.rgb)) * 8.0);
    color += (bg + bgFixed) * (1.0 - ink) * (1.0 - halo * HALO);

    // ── superfici e pellicola ──
#if SHADOW_MASK
    float triad = fmod(floor(pos.x / px), 3.0);
    float3 mask = float3(triad < 0.5, triad > 0.5 && triad < 1.5, triad > 1.5) * 0.5 + 0.62;
    color *= lerp(float3(1.0, 1.0, 1.0), mask, SHADOW_MASK_AMOUNT * (1.0 - ink * INK_PROTECT));
#endif

    float phase = 0.5 + 0.5 * cos(6.2831853 * pos.y / (SCANLINE_PX * px));
    color *= Protect(1.0 - SCANLINE_DIM * phase, ink);

#if ROLL_BAR
    float rb = frac(tex.y - Time * ROLL_SPEED);
    color *= Protect(1.0 - ROLL_DIM * smoothstep(0.0, 0.08, rb) * (1.0 - smoothstep(0.08, 0.22, rb)), ink);
#endif

    color += (Hash(floor(pos.xy)) - 0.5) * NOISE * (1.0 - ink * INK_PROTECT);
    float frameT = floor(Time * 24.0);
    color += (Hash(floor(pos.xy / px) + frameT) - 0.5) * GRAIN_ANIM * (1.0 - ink * INK_PROTECT);

#if SCRATCHES
    float scratch = step(0.9985, Hash(float2(floor(pos.x / (2.0 * px)), floor(Time * 6.0))));
    color = lerp(color, float3(0.8, 0.8, 0.8), scratch * 0.35 * (1.0 - ink * INK_PROTECT));
    float dust = step(0.99965, Hash(floor(pos.xy / (3.0 * px)) + frameT * 1.3));
    color *= 1.0 - dust * 0.85 * (1.0 - ink * INK_PROTECT);
#endif
    color *= Protect(1.0 - EXPOSURE_FLICKER * Hash(float2(frameT, 3.3)), ink);

#if VHS
    float row = floor(pos.y / (2.0 * px));
    float tape = step(0.9965, Hash(float2(row, floor(Time * 15.0))));
    color += tape * Hash(float2(floor(pos.x / (4.0 * px)), row)) * 0.3 * (1.0 - ink * INK_PROTECT);
    color += headZone * (Hash(pos.xy + Time) - 0.5) * 0.5;
#endif

#if GLITCH_BLOCKS
    // blocchi digitali con i canali scambiati
    float2 blk = floor(pos.xy / (float2(90.0, 14.0) * px));
    float bOn = step(0.992, Hash(blk + floor(Time * 3.0)));
    color = lerp(color, color.brg * float3(1.5, 0.5, 0.5), bOn);
#endif

#if HUD
    float2 hp = pos.xy / px;
    float gridL = saturate(step(frac(hp.x / 64.0), 1.0 / 64.0) + step(frac(hp.y / 64.0), 1.0 / 64.0));
    color += gridL * HUD_COLOR * 0.07;
    float sweepX = frac(Time * 0.12);
    color += exp(-abs(tex.x - sweepX) * 60.0) * HUD_COLOR * 0.22;
    float2 cp = (tex - 0.5) * float2(Resolution.x / Resolution.y, 1.0);
    float ring = smoothstep(0.004, 0.0, abs(length(cp) - 0.08));
    float crossV = smoothstep(0.0015, 0.0, abs(cp.x)) * step(abs(cp.y), 0.05) * step(0.02, abs(cp.y))
                 + smoothstep(0.0015, 0.0, abs(cp.y)) * step(abs(cp.x), 0.05) * step(0.02, abs(cp.x));
    color += (ring + crossV) * HUD_COLOR * 0.35;
#endif

#if USE_ANIM
    color += band * BAND_GLOW * BAND_COLOR;
    color *= Protect(1.0 - FLICKER * (0.5 + 0.5 * sin(Time * 47.0)), ink);
#endif

#if HOLO_BEAM
    // fascio del proiettore: più luminoso in basso, con raggi verticali appena percettibili
    color *= Protect(lerp(HOLO_TOP, 1.0, tex.y) * (0.92 + 0.08 * Noise(float2(tex.x * 40.0, Time * 0.5))), ink);
#endif

    // ── vignettatura, cornice, barre ──
    float2 d = tex - 0.5;
    color *= Protect(saturate(1.0 - dot(d, d) * VIGNETTE), ink);
    color += TINT;

    // leggibilità: il testo non scende mai sotto TEXT_MIN (stessa tinta della modalità, solo più luce)
    float lumOut = Luma(color);
    float lift = saturate((TEXT_MIN - lumOut) / TEXT_MIN) * ink;
    color = lerp(color, color * min(TEXT_MIN / max(lumOut, 0.03), 4.0), lift);

#if SEL_FIX
    color = lerp(color, float3(1.0, 1.0, 1.0), selText);
#endif

#if BEZEL
    // cornice arrotondata del televisore + riflesso sul vetro
    float2 q = abs(tex - 0.5) - (0.5 - BEZEL_SIZE - BEZEL_RADIUS);
    float sd = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - BEZEL_RADIUS;
    float screenMask = smoothstep(0.004, -0.004, sd);
    color *= 1.0 - smoothstep(-0.035, 0.0, sd) * 0.6;
    color += exp(-length((tex - float2(0.28, 0.18)) * float2(1.6, 2.6)) * 4.0) * 0.07;
    float3 frame = float3(0.04, 0.04, 0.045) + 0.035 * saturate(sd / BEZEL_SIZE);
    color = lerp(frame, color, screenMask);
    outside = 0.0;
#endif
#if LETTERBOX
    color *= lbMask;
#endif
    color *= 1.0 - outside;

    return float4(saturate(color), base.a);
}
