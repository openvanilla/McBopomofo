import Cocoa

public protocol FSEventStreamHelperDelegate: AnyObject {
    func helper(_ helper: FSEventStreamHelper, didReceive events: [FSEventStreamHelper.Event])
}

public class FSEventStreamHelper : NSObject {

    public struct Event {
        var path: String
        var flags: FSEventStreamEventFlags
        var id: FSEventStreamEventId
    }

    public let path: String
    public let dispatchQueue: DispatchQueue
    public weak var delegate: FSEventStreamHelperDelegate?

    @objc public init(path: String, queue: DispatchQueue) {
        self.path = path
        self.dispatchQueue = queue
    }

    private var stream: FSEventStreamRef? = nil

    public func start() -> Bool {
        if stream != nil {
            return false
        }
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        guard let stream = FSEventStreamCreate(nil, {
            (stream, clientCallBackInfo, eventCount, eventPaths, eventFlags, eventIds) in
            let helper = Unmanaged<FSEventStreamHelper>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
            let pathsBase = eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self)
            let pathsPtr = UnsafeBufferPointer(start: pathsBase, count: eventCount)
            let flagsPtr = UnsafeBufferPointer(start: eventFlags, count: eventCount)
            let eventIDsPtr = UnsafeBufferPointer(start: eventIds, count: eventCount)
            let events = (0..<eventCount).map {
                FSEventStreamHelper.Event(path: String(cString: pathsPtr[$0]),
                                          flags: flagsPtr[$0],
                                          id: eventIDsPtr[$0] )
            }
            helper.delegate?.helper(helper, didReceive: events)
        },
           &context,
           [path] as CFArray,
           UInt64(kFSEventStreamEventIdSinceNow),
           1.0,
           FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
        ) else {
            return false
        }

        FSEventStreamSetDispatchQueue(stream, dispatchQueue)
        if !FSEventStreamStart(stream) {
            FSEventStreamInvalidate(stream)
            return false
        }
        self.stream = stream
        return true
    }

    func stop() {
        guard let stream = stream else {
            return
        }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        self.stream = nil
    }
}

