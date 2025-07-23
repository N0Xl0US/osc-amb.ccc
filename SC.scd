s.boot;

(
SynthDef(\ambientHeaven, {
    |freq = 220, amp = 0.1, cutoff = 2000, pan = 0, reverbMix = 0.5, modSpeed = 0.07|
    var env, slowLFO, detune, shimmer, body, air, noise, lfoPan, sig, reverb;
    // Envelope with a slower attack & longer release for lushness
    env = EnvGen.kr(Env.asr(5, 1, 8), doneAction: 2);
    // Slow modulation to create subtle movement
    slowLFO = SinOsc.kr(modSpeed, 0, 0.02, 1);
    // Detuned harmonic sources (blend of sine & richer waves)
    detune = [0.99, 1.0, 1.01, 0.503, 1.498] * slowLFO;
    shimmer = Mix.fill(detune.size, { |i|
        Mix([
            SinOsc.ar(freq * detune[i], 0, amp / detune.size),
            LFTri.ar(freq * detune[i] * 2, 0, amp / (2 * detune.size)),
            Blip.ar(freq * detune[i], 3 + i, amp / (3 * detune.size))
        ])
    });
    // Filter shimmer for airiness
    air = BPF.ar(shimmer, cutoff, 0.4);
    // Add subtle filtered noise for texture
    noise = BPF.ar(WhiteNoise.ar(amp * 0.2), cutoff * 1.5, 0.2);
    // Stereo auto-panning
    lfoPan = SinOsc.kr(0.03).range(-0.7, 0.7);
    sig = Pan2.ar(air + noise, lfoPan);
    // Reverb for heavenly spatial wash
    reverb = FreeVerb.ar(sig, reverbMix, 0.8, 0.2); // FIXED: FreeVerb instead of JPverb
    // Dry/wet blend
    sig = XFade2.ar(sig, reverb, reverbMix * 2 - 1);
    Out.ar(0, sig * env);
}).add;



SynthDef(\dnbDrums, {
    |kickAmp = 0.6, snareAmp = 0.4, hatAmp = 0.2, bpm = 172, masterAmp = 0.4|

    var trig, hatTrig, glitchTrig, kick, snare, hat, glitch, out;
    var beatDur, kickSeq, snareSeq, kickPat, snarePat;
    var bpmMod, dynamicBPM;

    // Slight bpm modulation to mimic tempo drift
    bpmMod = LFNoise1.kr(0.05).range(-1, 1);
    dynamicBPM = bpm + bpmMod;
    beatDur = 60 / dynamicBPM;

    // Beat clocks
    trig = Impulse.kr(dynamicBPM / 60 * 2); // 1/8 step
    hatTrig = Dust.kr(16);  // irregular hats instead of fixed impulses
    glitchTrig = Dust.kr(4); // sparse glitch triggers

    // Rhythmic patterns
    kickSeq = Dseq([1, 0, 0, 1, 0, 1, 0, 0], inf);
    snareSeq = Dseq([0, 0, 1, 0, 1, 0, 0, 0], inf);
    kickPat = Demand.kr(trig, 0, kickSeq);
    snarePat = Demand.kr(trig, 0, snareSeq);

    // Kick drum
    kick = Decay2.kr(kickPat, 0.005, 0.25) *
        SinOsc.ar(50, 0, kickAmp) *
        EnvGen.kr(Env.perc(0.01, 0.15), kickPat);

    // Snare
    snare = Decay2.kr(snarePat, 0.004, 0.18) *
        (PinkNoise.ar(0.4) + SinOsc.ar(180, 0, 0.2)) * snareAmp;

    // Hi-hats with timing + filter variation
    hat = Decay2.kr(hatTrig, 0.002, 0.04) *
        BPF.ar(WhiteNoise.ar(0.2), TExpRand.kr(6000, 13000, hatTrig), 0.3) *
        TRand.kr(0.3, 1.0, hatTrig) * hatAmp;

    // Glitchy textures: short filtered bursts with freq changes
    glitch = Decay2.kr(glitchTrig, 0.005, 0.12) *
        BPF.ar(WhiteNoise.ar(0.5), TExpRand.kr(150, 3000, glitchTrig), 0.5) *
        LFNoise1.kr(6).range(0.2, 0.8);

    // Mix + global drum volume
    out = [kick + snare + hat + glitch, kick + snare + hat + glitch] * masterAmp;
    Out.ar(0, out);
}).add;


// Global synth instances
~x = Synth(\ambientHeaven, [\freq, 220, \amp, 0.4, \cutoff, 2500, \pan, 0, \reverbMix, 0.6]);
~drums = Synth(\dnbDrums, [
    \kickAmp, 0.7,
    \snareAmp, 0.4,
    \hatAmp, 0.3,
    \bpm, 172,
    \masterAmp, 0.5   // Lower this to prioritize ambience
]);


// OSC responders for ambientHeaven
OSCdef(\oscFreq,    { |msg| ~x.set(\freq, msg[1]); }, "/temp");
OSCdef(\oscAmp,     { |msg| ~x.set(\amp, msg[1]); }, "/light");
OSCdef(\oscCutoff,  { |msg| ~x.set(\cutoff, msg[1]); }, "/cutoff");
OSCdef(\oscPan,     { |msg| ~x.set(\pan, msg[1]); }, "/pan");
OSCdef(\oscReverb,  { |msg| ~x.set(\reverbMix, msg[1]); }, "/reverb");
OSCdef(\oscModSpeed, { |msg| ~x.set(\modSpeed, msg[1]); }, "/mod_speed"); // NEW: modSpeed responder
)
