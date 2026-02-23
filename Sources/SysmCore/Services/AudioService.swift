import CoreAudio
import Foundation

public struct AudioService: AudioServiceProtocol {
    public init() {}

    public func getVolume() throws -> AudioVolumeInfo {
        let deviceId = try getDefaultOutputDeviceId()

        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceId, &address, 0, nil, &size, &volume)
        guard status == noErr else {
            throw AudioError.propertyReadFailed("volume", status)
        }

        let muted = try isMuted(deviceId: deviceId)
        return AudioVolumeInfo(volume: Int(round(volume * 100)), isMuted: muted)
    }

    public func setVolume(_ percent: Int) throws {
        guard percent >= 0 && percent <= 100 else {
            throw AudioError.volumeOutOfRange(percent)
        }

        let deviceId = try getDefaultOutputDeviceId()
        var volume = Float32(percent) / 100.0
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(deviceId, &address, 0, nil, size, &volume)
        guard status == noErr else {
            throw AudioError.propertyWriteFailed("volume", status)
        }
    }

    public func mute() throws {
        let deviceId = try getDefaultOutputDeviceId()
        try setMute(deviceId: deviceId, muted: true)
    }

    public func unmute() throws {
        let deviceId = try getDefaultOutputDeviceId()
        try setMute(deviceId: deviceId, muted: false)
    }

    public func listDevices() throws -> [AudioDeviceInfo] {
        let deviceIds = try getDeviceIds()
        return try deviceIds.compactMap { try getDeviceInfo(deviceId: $0) }
    }

    public func getDefaultInput() throws -> AudioDefaultDevice {
        let deviceId = try getDefaultInputDeviceId()
        let name = try getDeviceName(deviceId: deviceId)
        let uid = try? getDeviceUID(deviceId: deviceId)
        return AudioDefaultDevice(deviceId: deviceId, name: name, uid: uid, isInput: true)
    }

    public func getDefaultOutput() throws -> AudioDefaultDevice {
        let deviceId = try getDefaultOutputDeviceId()
        let name = try getDeviceName(deviceId: deviceId)
        let uid = try? getDeviceUID(deviceId: deviceId)
        return AudioDefaultDevice(deviceId: deviceId, name: name, uid: uid, isInput: false)
    }

    public func setDefaultInput(name: String) throws {
        let devices = try listDevices()
        guard let device = devices.first(where: { $0.name.localizedCaseInsensitiveContains(name) && $0.isInput }) else {
            throw AudioError.deviceNotFound(name)
        }
        var deviceId = device.id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &deviceId)
        guard status == noErr else {
            throw AudioError.propertyWriteFailed("default input", status)
        }
    }

    public func setDefaultOutput(name: String) throws {
        let devices = try listDevices()
        guard let device = devices.first(where: { $0.name.localizedCaseInsensitiveContains(name) && $0.isOutput }) else {
            throw AudioError.deviceNotFound(name)
        }
        var deviceId = device.id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &deviceId)
        guard status == noErr else {
            throw AudioError.propertyWriteFailed("default output", status)
        }
    }

    // MARK: - Private Helpers

    private func getDefaultOutputDeviceId() throws -> AudioDeviceID {
        var deviceId = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceId)
        guard status == noErr else {
            throw AudioError.propertyReadFailed("default output device", status)
        }
        return deviceId
    }

    private func getDefaultInputDeviceId() throws -> AudioDeviceID {
        var deviceId = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceId)
        guard status == noErr else {
            throw AudioError.propertyReadFailed("default input device", status)
        }
        return deviceId
    }

    private func getDeviceIds() throws -> [AudioDeviceID] {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
        guard status == noErr else {
            throw AudioError.propertyReadFailed("device list", status)
        }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var deviceIds = [AudioDeviceID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceIds)
        guard status == noErr else {
            throw AudioError.propertyReadFailed("device list", status)
        }

        return deviceIds
    }

    private func getStringProperty(deviceId: AudioDeviceID, selector: AudioObjectPropertySelector) throws -> String {
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(deviceId, &address, 0, nil, &size, &value)
        guard status == noErr, let cfString = value?.takeUnretainedValue() else {
            throw AudioError.propertyReadFailed("string property", status)
        }
        return cfString as String
    }

    private func getDeviceName(deviceId: AudioDeviceID) throws -> String {
        try getStringProperty(deviceId: deviceId, selector: kAudioObjectPropertyName)
    }

    private func getDeviceUID(deviceId: AudioDeviceID) throws -> String {
        try getStringProperty(deviceId: deviceId, selector: kAudioDevicePropertyDeviceUID)
    }

    private func getDeviceManufacturer(deviceId: AudioDeviceID) -> String? {
        try? getStringProperty(deviceId: deviceId, selector: kAudioObjectPropertyManufacturer)
    }

    private func getStreamCount(deviceId: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyDataSize(deviceId, &address, 0, nil, &size)
        guard status == noErr else { return 0 }
        return Int(size) / MemoryLayout<AudioStreamID>.size
    }

    private func getChannelCount(deviceId: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyDataSize(deviceId, &address, 0, nil, &size) == noErr, size > 0 else { return 0 }

        let data = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { data.deallocate() }

        guard AudioObjectGetPropertyData(deviceId, &address, 0, nil, &size, data) == noErr else { return 0 }

        let bufferList = data.assumingMemoryBound(to: AudioBufferList.self).pointee
        var channels = 0
        withUnsafePointer(to: bufferList.mBuffers) { ptr in
            for i in 0..<Int(bufferList.mNumberBuffers) {
                let buffer = UnsafeRawPointer(ptr).advanced(by: i * MemoryLayout<AudioBuffer>.stride)
                    .assumingMemoryBound(to: AudioBuffer.self).pointee
                channels += Int(buffer.mNumberChannels)
            }
        }
        return channels
    }

    private func getSampleRate(deviceId: AudioDeviceID) -> Double {
        var sampleRate: Float64 = 0
        var size = UInt32(MemoryLayout<Float64>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(deviceId, &address, 0, nil, &size, &sampleRate)
        guard status == noErr else { return 0 }
        return sampleRate
    }

    private func isMuted(deviceId: AudioDeviceID) throws -> Bool {
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Some devices don't support mute property, return false in that case
        guard AudioObjectHasProperty(deviceId, &address) else {
            return false
        }

        let status = AudioObjectGetPropertyData(deviceId, &address, 0, nil, &size, &muted)
        guard status == noErr else {
            return false
        }
        return muted != 0
    }

    private func setMute(deviceId: AudioDeviceID, muted: Bool) throws {
        var muteValue: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(deviceId, &address, 0, nil, size, &muteValue)
        guard status == noErr else {
            throw AudioError.propertyWriteFailed("mute", status)
        }
    }

    private func getDeviceInfo(deviceId: AudioDeviceID) throws -> AudioDeviceInfo? {
        let name = try getDeviceName(deviceId: deviceId)
        let manufacturer = getDeviceManufacturer(deviceId: deviceId)
        let uid = try? getDeviceUID(deviceId: deviceId)
        let hasInput = getStreamCount(deviceId: deviceId, scope: kAudioDevicePropertyScopeInput) > 0
        let hasOutput = getStreamCount(deviceId: deviceId, scope: kAudioDevicePropertyScopeOutput) > 0
        let sampleRate = getSampleRate(deviceId: deviceId)

        let inputChannels = getChannelCount(deviceId: deviceId, scope: kAudioDevicePropertyScopeInput)
        let outputChannels = getChannelCount(deviceId: deviceId, scope: kAudioDevicePropertyScopeOutput)
        let channels = max(inputChannels, outputChannels)

        return AudioDeviceInfo(
            id: deviceId,
            name: name,
            manufacturer: manufacturer,
            uid: uid,
            isInput: hasInput,
            isOutput: hasOutput,
            sampleRate: sampleRate,
            channels: channels
        )
    }
}

public enum AudioError: LocalizedError {
    case deviceNotFound(String)
    case volumeOutOfRange(Int)
    case propertyReadFailed(String, OSStatus)
    case propertyWriteFailed(String, OSStatus)

    public var errorDescription: String? {
        switch self {
        case .deviceNotFound(let name):
            return "Audio device not found: \(name)"
        case .volumeOutOfRange(let value):
            return "Volume \(value) out of range (must be 0-100)"
        case .propertyReadFailed(let prop, let status):
            return "Failed to read \(prop) (status: \(status))"
        case .propertyWriteFailed(let prop, let status):
            return "Failed to write \(prop) (status: \(status))"
        }
    }
}
