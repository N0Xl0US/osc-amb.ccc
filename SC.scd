s.boot;

(
// Ambient synth with reverb, pan, filter cutoff
SynthDef(\ambientDrone, {
    |freq = 220, amp = 0.1, cutoff = 2000, pan = 0, reverbMix = 0.3|
    var sig, env, rev;
    env = EnvGen.kr(Env.asr(0.5, 1, 2), doneAction: 2);
    sig = Mix.fill(3, { |i|
        var detune = [0, 0.99, 1.01][i];
        SinOsc.ar(freq * detune, 0, amp/3)
    });
    sig = RLPF.ar(sig, cutoff, 0.2);
    sig = sig * env;
    sig = Pan2.ar(sig, pan);
    rev = FreeVerb.ar(sig, reverbMix, 0.8, 0.2);
    Out.ar(0, XFade2.ar(sig, rev, reverbMix*2-1));
}).add;

// DNB Drum Synth (stereo)
SynthDef(\dnbDrums, { |kickAmp=0.8, snareAmp=0.5, hatAmp=0.3, hatRate=8, snareRate=2, kickRate=2|
    // Groove: add swing to hats, randomize snare
    var swing = 0.12;
    var hatTrig = TDuty.kr(Dseq([0.5, 0.5 + swing], inf) / hatRate, 0, 1);
    var snareTrig = TDuty.kr(Dseq([0.5, 0.5 + swing], inf) / snareRate, 0, 1) * (TRand.kr(0, 1, Impulse.kr(snareRate)) > 0.3);
    var kickTrig = Impulse.kr(kickRate);

    // Kick: punchy, more body
    var kick = Decay2.kr(kickTrig, 0.005, 0.18) *
        SinOsc.ar(EnvGen.kr(Env([60, 40], [0.04]), kickTrig) * 60, 0, kickAmp);

    // Snare: noise burst + body, randomize amplitude
    var snare = Decay2.kr(snareTrig, 0.005, 0.18) *
        (WhiteNoise.ar(0.3) + SinOsc.ar(180, 0, 0.2)) * snareAmp * TRand.kr(0.7, 1.0, snareTrig);

    // Hi-hat: filtered noise, swing, stereo
    var hatL = Decay2.kr(hatTrig, 0.001, 0.04) * BPF.ar(WhiteNoise.ar(0.2), 8000, 0.5) * hatAmp;
    var hatR = Decay2.kr(hatTrig, 0.001, 0.04) * BPF.ar(WhiteNoise.ar(0.2), 9000, 0.5) * hatAmp;

    var out = [kick + snare + hatL, kick + snare + hatR];
    Out.ar(0, out);
}).add;

// Global synth instances
~x = Synth(\ambientDrone, [\freq, 220, \amp, 0.2, \cutoff, 2000, \pan, 0, \reverbMix, 0.3]);
// Global DNB drum synth instance (fixed parameters, always running)
~dnb = Synth(\dnbDrums, [\kickAmp, 0.9, \snareAmp, 0.6, \hatAmp, 0.3, \hatRate, 8, \snareRate, 2, \kickRate, 2]);

// OSC responders
OSCdef(\oscFreq, { |msg| ~x.set(\freq, msg[1]); }, "/temp");
OSCdef(\oscAmp,  { |msg| ~x.set(\amp, msg[1]);  }, "/light");
OSCdef(\oscCutoff, { |msg| ~x.set(\cutoff, msg[1]); }, "/cutoff");
OSCdef(\oscPan, { |msg| ~x.set(\pan, msg[1]); }, "/pan");
OSCdef(\oscReverb, { |msg| ~x.set(\reverbMix, msg[1]); }, "/reverb");
)

