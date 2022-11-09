//
//  Bank.swift
//  BankManagerConsoleApp
//
//  Created by Kyo, Wonbi on 2022/11/02.
//

import Foundation

final class Bank<Queue: ClientQueueable> {
    private let bankDispatchGroup = DispatchGroup()
    private let depositBooth = DispatchSemaphore(value: 2)
    private let loanBooth = DispatchQueue(label: "loanBanker")
    
    private let banker: BankWorkable
    private var clientQueue: Queue
    private var bankManager: BankManagable
    
    init(banker: BankWorkable, queue: Queue, bankManager: BankManagable) {
        self.banker = banker
        self.clientQueue = queue
        self.bankManager = bankManager
    }
    
    func openBank() {
        updateClientQueue()
        startBankWork()
        endBankWork()
    }
    
    private func updateClientQueue() {
        for number in 1...Int.random(in: 10...30) {
            guard let randomPurpose = Client.Purpose.allCases.randomElement() else { return }
            let client = Client(waitingTicket: number, purpose: randomPurpose)
            clientQueue.enqueue(client)
            bankManager.addClientCount()
        }
    }
    
    private func startBankWork() {
        bankManager.resetWorkTime()
        
        while !clientQueue.isEmpty {
            guard let client = clientQueue.dequeue() else { return }
            
            divideWork(client: client)
        }
        
        bankDispatchGroup.wait()
        bankManager.addWorkTime()
    }
    
    private func divideWork(client: Client) {
        switch client.purpose {
        case .deposit:
            DispatchQueue.global().async(group: bankDispatchGroup) { [self] in
                self.depositBooth.wait()
                defer { self.depositBooth.signal() }
                
                self.banker.startWork(client: client)
            }
        case .loan:
            loanBooth.async(group: bankDispatchGroup) { [self] in
                self.banker.startWork(client: client)
            }
        }
    }
    
    private func endBankWork() {
        bankManager.printWorkFinished()
    }
}
