//
//  SRPClient.swift
//  ProtonMail - Created on 10/6/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


public class Proofs {
    public var clientEphemeral : Data
    public var clientProof : Data
    public var expectedServerProof : Data
    
    public init (ephemeral : Data, proof : Data, serverProof :Data ) {
        self.clientEphemeral = ephemeral
        self.clientProof = proof
        self.expectedServerProof = serverProof
    }
}
