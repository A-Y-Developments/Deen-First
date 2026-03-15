import Foundation
import Alamofire

final class NetworkLoggingInterceptor: EventMonitor {
    func requestDidResume(_ request: Request) {
        #if DEBUG
        print("🌐 [REQUEST] \(request.request?.httpMethod ?? "GET") \(request.request?.url?.absoluteString ?? "unknown")")
        #endif
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        #if DEBUG
        switch response.result {
        case .success:
            if let httpResponse = response.response {
                print("✅ [RESPONSE] \(httpResponse.statusCode)")
            }
        case .failure(let error):
            print("❌ [ERROR] \(error.localizedDescription)")
        }
        #endif
    }
}
