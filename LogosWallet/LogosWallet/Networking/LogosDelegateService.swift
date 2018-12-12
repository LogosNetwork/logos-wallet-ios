//
//  LogosDelegateService.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/11/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Moya

enum LogosDelegateService {
    case delegates

    static func loadBalancedIndex() -> Int {

        return 0
    }
}

extension LogosDelegateService: TargetType {
    var baseURL: URL {
        return URL(string: "https://pla.bs/delegates")!
    }
    var path: String {
        return ""
    }
    var method: Moya.Method {
        return .get
    }
    var sampleData: Data {
        return Data()
    }
    var task: Task {
        return .requestPlain
    }
    var headers: [String : String]? {
        return nil
    }

}
