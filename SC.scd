s.boot;

(
SynthDef(\ambientHeaven, {
    |freq = 220, amp = 0.1, cutoff = 2500, pan = 0, reverbMix = 0.6, modSpeed = 0.05,
      shimmerMix = 0.45, chorusDepth = 0.012, chorusRate = 0.12, width = 0.95,
      reverbRoom = 0.95, reverbDamp = 0.35, airFreq = 9500, airGain = 5, hp = 90,
      preDelay = 0.035, bpm = 172, rhythmAmt = 0.12, duckBus = 0, duckAmount = 0.45, wetDuck = 0.25,
      fxBus = 0, sendLevel = 0.4|
    var env, slowLFO, brightLFO, sines, baseSaw, fifthSaw, octaveSaw, padCore, airTex;
    var lfoPan, preFX, chorus, wetIn, reverb, shimmerOct, shimmerFifth, wet, dry, outSig;
    var trig16, pulse, duckSig, pumpDry, pumpWet;

    // Envelope for huge, slow pad
    env = EnvGen.kr(Env.asr(8, 1, 12), doneAction: 2);

    // Motion and brightness drift
    slowLFO = SinOsc.kr(modSpeed, 0, 0.02, 1);
    brightLFO = SinOsc.kr(0.02).range(0.7, 1.3);

    // Analog-style supersaw stacks: root, fifth, octave
    baseSaw = Mix.fill(7, { |i|
        var det = (i - 3) * 0.004 + (SinOsc.kr(0.03 + (i * 0.005)).range(-0.0008, 0.0008));
        VarSaw.ar(freq * (1 + det) * slowLFO, 0, 0.7, amp * 0.08)
    });
    fifthSaw = Mix.fill(5, { |i|
        var det = (i - 2) * 0.0035;
        VarSaw.ar(freq * 1.5 * (1 + det), 0, 0.65, amp * 0.05)
    });
    octaveSaw = Mix.fill(5, { |i|
        var det = (i - 2) * 0.003;
        VarSaw.ar(freq * 2 * (1 + det), 0, 0.6, amp * 0.04)
    });
    sines = SinOsc.ar(freq * [1, 2], 0, amp * [0.03, 0.02]);
    padCore = baseSaw + fifthSaw + octaveSaw + Mix(sines);
    // Rhythm pulse synced to bpm (1/16)
    trig16 = Impulse.kr(bpm / 60 * 4);
    pulse = Decay2.kr(trig16, 0.002, 0.08);
    // Gentle dynamic lowpass tilt + rhythmic lift
    padCore = padCore * (1 + (pulse * rhythmAmt));
    padCore = RLPF.ar(padCore, (cutoff * brightLFO * (1 + (pulse * rhythmAmt * 0.6))).clip(200, 18000), 0.35);

    // Air layer (very subtle)
    airTex = BPF.ar(WhiteNoise.ar(amp * 0.06), cutoff * 1.8, 0.2);

    // Stereo spread + slow autopan
    lfoPan = SinOsc.kr(0.018).range(-0.55, 0.55) + pan;
    preFX = Splay.ar([padCore + airTex], spread: width, level: 1.0);
    preFX = Balance2.ar(preFX[0], preFX[1], lfoPan.max(-1).min(1));

    // Subtle chorus before reverb
    chorus = preFX + DelayC.ar(preFX, 0.03, SinOsc.kr(chorusRate).range(0.001, chorusDepth));

    // Predelay then fully-wet verb; blend later
    wetIn = DelayN.ar(chorus, 0.1, preDelay);
    reverb = FreeVerb.ar(wetIn, 1.0, reverbRoom, reverbDamp);

    // Shimmer: octave + fifth
    shimmerOct = PitchShift.ar(reverb, 0.25, 2.0, 0.01, 0.02);
    shimmerFifth = PitchShift.ar(reverb, 0.25, 1.5, 0.01, 0.02);
    wet = (reverb * (1 - shimmerMix)) + ((shimmerOct * 0.7 + shimmerFifth * 0.3) * shimmerMix);

    // Sidechain ducking from drums
    duckSig = In.kr(duckBus, 1).clip(0, 1);
    pumpDry = (1 - (duckSig * duckAmount));
    pumpWet = (1 - (duckSig * wetDuck));
    dry = chorus * pumpDry;
    outSig = XFade2.ar(dry, (wet * pumpWet), (reverbMix * 2 - 1));
    // Send a cohesive dry image to global heaven FX
    Out.ar(fxBus, preFX * sendLevel);

    // Heavenly tone shaping
    outSig = HPF.ar(outSig, hp);
    outSig = BHiShelf.ar(outSig, airFreq, 0.7, airGain);
    outSig = Compander.ar(outSig, outSig, 0.5, 1, 0.2, 0.01, 0.2);
    Out.ar(0, Limiter.ar(outSig * env, 0.95));
}).add;



// Heavenly arpeggiator that complements the pad and locks to BPM (now feeds global FX bus)
SynthDef(\heavenArp, {
    |freq = 220, amp = 0.07, bpm = 172, rateMult = 4,
      arpCutoff = 5200, arpRes = 0.22, envA = 0.002, envD = 0.12, filterAmt = 3800,
      width = 0.6, reverbMix = 0.16, pan = 0,
      arpDensity = 0.32, burstRate = 0.10, burstDecay = 2.6, jitter = 0.018,
      ratchetProb = 0.12, duckBus = 0, duckAmount = 0.35, fxBus = 0, sendLevel = 0.25|
    var stepTrig, barTrig, step;
    var burstTrig, burstEnv, gateMask, hitTrig0, jitterAmt, jTrig, ratchetOn, totalTrig;
    var scale, idx, semiStep, barOctBoost, vibSemi, ratio;
    var ampEnv, filtEnv, osc, bright, sig, wet, pump, duckSig;

    // Clocks and step index
    stepTrig = Impulse.kr(bpm / 60 * rateMult);
    barTrig = Impulse.kr((bpm / 60) / 4);
    step = PulseCount.kr(stepTrig) % 16;

    // Random burst envelope to make arp appear sporadically
    burstTrig = Dust.kr(burstRate);
    burstEnv = EnvGen.kr(Env.perc(0.01, burstDecay, 1, -4), burstTrig);

    // Per-step random gating shaped by burst envelope
    gateMask = (TRand.kr(0.0, 1.0, stepTrig) < (arpDensity * burstEnv));
    hitTrig0 = stepTrig * gateMask;

    // Microtiming jitter (up to 'jitter' seconds)
    jitterAmt = TRand.kr(0.0, jitter, hitTrig0);
    jTrig = DelayN.kr(hitTrig0, 0.05, jitterAmt);

    // Occasional ratchets (extra rapid repeats)
    ratchetOn = (TRand.kr(0.0, 1.0, jTrig) < ratchetProb);
    totalTrig = jTrig + (TDelay.kr(jTrig, 0.05) * ratchetOn) + (TDelay.kr(jTrig, 0.095) * ratchetOn);

    // Aphex-ish pitch pool (modal mixture) chosen per step
    scale = [0, 1, 3, 5, 7, 8, 10, 12, 14];
    idx = TIRand.kr(0, scale.size - 1, stepTrig);
    semiStep = Select.kr(idx, scale);

    // Occasional octave lift per bar and gentle micro-vibrato
    barOctBoost = 12 * (TRand.kr(0.0, 1.0, barTrig) < 0.2);
    vibSemi = SinOsc.kr(0.13, 0, 0.06);
    ratio = (semiStep + barOctBoost + vibSemi).midiratio;

    // Envelopes
    ampEnv = EnvGen.kr(Env.perc(envA, envD, 1, -4), totalTrig);
    filtEnv = EnvGen.kr(Env.perc(0.001, envD * 0.9, 1, -4), totalTrig);

    // Crisp pluck: narrow pulse + varsaw, filter sweep
    osc = (Pulse.ar(freq * ratio, 0.25) * 0.65) + (VarSaw.ar(freq * ratio * 2.01, 0, 0.85) * 0.35);
    bright = RLPF.ar(osc, (arpCutoff + (filterAmt * filtEnv)).clip(200, 18000), arpRes);
    sig = bright * (ampEnv * amp);

    // Stereo and tail (kept subtle)
    sig = Splay.ar(sig, spread: width, level: 1.0, center: pan);
    wet = FreeVerb.ar(sig, reverbMix, 0.86, 0.25);

    // Sidechain ducking
    duckSig = In.kr(duckBus, 1).clip(0, 1);
    pump = (1 - (duckSig * duckAmount));
    sig = (sig * pump) + (wet * pump * 0.6);
    Out.ar(fxBus, sig * sendLevel);

    Out.ar(0, sig);
}).add;


SynthDef(\heavenFXBus, {
    |inBus = 20, out = 0, mix = 0.6, size = 0.98, damp = 0.35, shimmer = 0.5, hp = 120, airFreq = 10000, airGain = 4|
    var send = In.ar(inBus, 2);
    var rev = FreeVerb.ar(send, mix, size, damp);
    var shin = PitchShift.ar(rev, 0.25, 2.0, 0.02, 0.02);
    var wet = XFade2.ar(rev, shin, shimmer * 2 - 1);
    var outSig = HPF.ar(wet, hp);
    outSig = BHiShelf.ar(outSig, airFreq, 0.7, airGain);
    Out.ar(out, outSig);
}).add;

SynthDef(\dnbDrums, {
    |kickAmp = 0.6, snareAmp = 0.4, hatAmp = 0.2, bpm = 172, masterAmp = 0.4,
      patternVar = 0.1, fillProb = 0.4, hatDensity = 0.85|

    var trig16, barTrig, barIndex, hatTrig, glitchTrig, kick, snare, hat, glitch, out;
    var step, bpmMod, dynamicBPM;
    var kickPatterns, snarePatterns, kickSel, snareSel;
    var kickAddMask, kickRemoveMask, kickVar;
    var snareAddMask, snareRemoveMask, snareVarNormal, snareFillArray, isFillBar, fillRand, fillOn;
    var kickStep, snareStepNormal, snareStepFill, snareStep, kickTrig, snareTrig;

    bpmMod = LFNoise1.kr(0.05).range(-1, 1);
    dynamicBPM = bpm + bpmMod;

    // Clocks
    trig16 = Impulse.kr(dynamicBPM / 60 * 4); // 1/16 grid
    barTrig = Impulse.kr((dynamicBPM / 60) / 4); // once per 4/4 bar
    barIndex = PulseCount.kr(barTrig) % 4;
    glitchTrig = Dust.kr(4); // sparse glitch triggers
    step = PulseCount.kr(trig16) % 16; // step index 0..15

    // 4-bar pattern cycle
    kickPatterns = [
        [1, 0, 0, 1,  0, 0, 1, 0,  1, 0, 0, 1,  0, 1, 0, 0],
        [1, 0, 0, 1,  0, 1, 0, 0,  1, 0, 1, 0,  0, 1, 0, 0],
        [1, 0, 0, 1,  0, 0, 1, 0,  1, 0, 0, 0,  1, 0, 1, 0],
        [1, 0, 1, 0,  0, 1, 0, 0,  1, 0, 0, 1,  0, 1, 0, 0]
    ];
    snarePatterns = [
        [0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0],
        [0, 0, 1, 0,  0, 1, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0],
        [0, 0, 1, 0,  0, 0, 1, 0,  0, 1, 1, 0,  0, 0, 1, 0],
        [0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 1, 1, 0]
    ];
    kickSel = Array.fill(16, { |i|
        Select.kr(barIndex, [kickPatterns[0][i], kickPatterns[1][i], kickPatterns[2][i], kickPatterns[3][i]])
    });
    snareSel = Array.fill(16, { |i|
        Select.kr(barIndex, [snarePatterns[0][i], snarePatterns[1][i], snarePatterns[2][i], snarePatterns[3][i]])
    });


    kickAddMask = Array.fill(16, { TRand.kr(0.0, 1.0, barTrig) < patternVar });
    kickRemoveMask = Array.fill(16, { TRand.kr(0.0, 1.0, barTrig) < (patternVar * 0.6) });
    kickVar = (kickSel + kickAddMask - kickRemoveMask).clip(0, 1);

    snareAddMask = Array.fill(16, { TRand.kr(0.0, 1.0, barTrig) < (patternVar * 0.7) });
    snareRemoveMask = Array.fill(16, { TRand.kr(0.0, 1.0, barTrig) < (patternVar * 0.3) });
    snareVarNormal = (snareSel + snareAddMask - snareRemoveMask).clip(0, 1);

    snareFillArray = [0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1,  0, 1, 1, 1];
    isFillBar = Select.kr(barIndex, [0, 0, 0, 1]);
    fillRand = (TRand.kr(0.0, 1.0, barTrig) < fillProb);
    fillOn = isFillBar * fillRand; // 0 or 1 as UGen

    kickStep = Select.kr(step, kickVar);
    snareStepNormal = Select.kr(step, snareVarNormal);
    snareStepFill = Select.kr(step, snareFillArray);
    snareStep = snareStepNormal + (snareStepFill - snareStepNormal) * fillOn;
    kickTrig = trig16 * kickStep;
    snareTrig = trig16 * snareStep;


    kick = Decay2.kr(kickTrig, 0.005, 0.25) *
        SinOsc.ar(50, 0, kickAmp) *
        EnvGen.kr(Env.perc(0.005, 0.12), kickTrig);

    snare = Decay2.kr(snareTrig, 0.003, 0.18) *
        (PinkNoise.ar(0.5) + SinOsc.ar(180, 0, 0.2)) * snareAmp;

    hatTrig = trig16 * (TRand.kr(0.0, 1.0, trig16) < hatDensity);
    hat = Decay2.kr(hatTrig, 0.002, 0.045) *
        BPF.ar(WhiteNoise.ar(0.2), TExpRand.kr(6000, 13000, hatTrig), 0.3) *
        TRand.kr(0.3, 1.0, hatTrig) * hatAmp;

    glitch = Decay2.kr(glitchTrig, 0.005, 0.12) *
        BPF.ar(WhiteNoise.ar(0.5), TExpRand.kr(150, 3000, glitchTrig), 0.5) *
        LFNoise1.kr(6).range(0.2, 0.8);

    out = [kick + snare + hat + glitch, kick + snare + hat + glitch] * masterAmp;
    Out.ar(0, out);
}).add;


// Global synth instances
~x = Synth(\ambientHeaven, [\freq, 220, \amp, 0.4, \cutoff, 2500, \pan, 0, \reverbMix, 0.6, \bpm, 172, \duckBus, 10, \fxBus, 20, \sendLevel, 0.35]);
~drums = Synth(\dnbDrums, [
    \kickAmp, 0.7,
    \snareAmp, 0.4,
    \hatAmp, 0.3,
    \bpm, 172,
    \masterAmp, 0.5   // Balance
]);

// Drum envelope follower to control synth ducking
~duckTap = { |bus = 10|
    var src = In.ar(0, 2); // tap main out
    var mono = LeakDC.ar(HPF.ar(src.sum * 0.5, 40));
    var env = Amplitude.kr(mono, 0.002, 0.15).clip(0, 1);
    Out.kr(bus, env);
}.play(addAction: \addToHead);

// Global heaven FX bus instance 
~fx = Synth(\heavenFXBus, [\inBus, 20, \out, 0, \mix, 0.65, \size, 0.98, \damp, 0.35, \shimmer, 0.55, \hp, 110, \airFreq, 10500, \airGain, 5]);


~arp = Synth(\heavenArp, [
    \freq, 220,
    \amp, 0.07,
    \bpm, 172,
    \rateMult, 4,          
    \arpCutoff, 5000,
    \filterAmt, 3800,
    \reverbMix, 0.12,
    \width, 0.7,
    \arpDensity, 0.28,
    \burstRate, 0.10,
    \burstDecay, 2.6,
    \ratchetProb, 0.12,
    \jitter, 0.018,
    \duckBus, 10,
    \duckAmount, 0.35,
    \fxBus, 20, \sendLevel, 0.3
]);


// OSC responders for ambientHeaven
OSCdef(\oscFreq,    { |msg| ~x.set(\freq, msg[1]); }, "/temp");
OSCdef(\oscAmp,     { |msg| ~x.set(\amp, msg[1]); }, "/light");
OSCdef(\oscCutoff,  { |msg| ~x.set(\cutoff, msg[1]); }, "/cutoff");
OSCdef(\oscPan,     { |msg| ~x.set(\pan, msg[1]); }, "/pan");
OSCdef(\oscReverb,  { |msg| ~x.set(\reverbMix, msg[1]); }, "/reverb");
OSCdef(\oscModSpeed, { |msg| ~x.set(\modSpeed, msg[1]); }, "/mod_speed"); // NEW: modSpeed responder
)
