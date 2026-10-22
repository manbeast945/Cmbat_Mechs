extends RefCounted
class_name CombatSounds

static func make_whoosh() -> AudioStreamWAV:
	return _make_wave(0)

static func make_impact() -> AudioStreamWAV:
	return _make_wave(1)

static func _make_wave(kind: int) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.19 if kind == 0 else 0.10
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var progress := time / duration
		var sample: float
		if kind == 0:
			var envelope := sin(PI * progress) * 0.24
			var noise := randf_range(-1.0, 1.0)
			var tone := sin(TAU * (260.0 - 130.0 * progress) * time) * 0.25
			sample = (noise * 0.75 + tone) * envelope
		else:
			var envelope := exp(-progress * 11.0)
			var thud := sin(TAU * 105.0 * time) * 0.72
			var click := randf_range(-1.0, 1.0) * 0.22
			sample = (thud + click) * envelope * 0.42
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
