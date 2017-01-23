//
//  TetrisEngine.swift
//  Tetris Engine
//
//  Created by Martin Kiss on 16 Jan 2017.
//  https://github.com/Tricertops/TetrisEngine
//
//  The MIT License (MIT)
//  Copyright © 2017 Martin Kiss
//

import Foundation


class Engine {
    
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) {
        assert(width >= 4)
        assert(height >= 10)
        self.width = width
        self.height = height
        
        board = Board(width: width, height: height + 5)
        
        currentBlock = Block(shape: .T)
        nextBlock = Block(shape: .T)
        
        state = .initialized
    }
    
    
    enum State {
        case initialized
        case running
        case paused
        case stopped
    }
    var state: State
    
    var timer: Timer?
    var interval: TimeInterval {
        let initial = 1.0
        let step = 0.02
        return max(initial - Double(score) * step, step)
    }
    
    var score: Int = 0 {
        didSet {
            runTimer()
        }
    }
    
    func runTimer() {
        stopTimer()
        
        let date = Date(timeIntervalSinceNow: interval)
        timer = Timer(fire: date, interval: interval, repeats: yes) {
            [unowned self] _ in
            self.timerTick()
        }
        
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func start() {
        score = 0
        board.clear()
        recentShapes = []
        currentBlock = generateNextBlock().placed(above: height, in: board)
        nextBlock = generateNextBlock()
        
        callback?(.startGame)
        callback?(.newPiece)
        
        runTimer()
        state = .running
    }
    
    func pause() {
        stopTimer()
        state = .paused
    }
    
    func resume() {
        runTimer()
        state = .running
    }
    
    func stop() {
        stopTimer()
        state = .stopped
    }
    
    func timerTick() {
        if state != .running {
            return
        }
        if currentBlock.canFall(in: board) {
            currentBlock.fall()
            callback?(.fall)
        }
        else if case .falling = currentBlock.cell {
            currentBlock.makeObstacle()
            
            let completed = board.findCompletedLines()
            if completed.count > 0 {
                board.remove(lines: completed)
                score += completed.count
                callback?(.completed(lines: completed))
            }
            
            if board.isObstacle(above: height) {
                callback?(.gameOver)
                stop()
            }
        }
        else {
            currentBlock = nextBlock.placed(above: height, in: board)
            nextBlock = generateNextBlock()
            callback?(.newPiece)
        }
    }
    
    var currentBlock: Block {
        willSet {
            let oldBlock = currentBlock
            if oldBlock.isFalling {
                for position in oldBlock.absolutePositions {
                    board.set(cell: .empty, at: position)
                }
            }
        }
        didSet {
            let newBlock = currentBlock
            let cell: Cell = newBlock.cell
            
            for position in newBlock.absolutePositions {
                board.set(cell: cell, at: position)
            }
        }
    }
    var nextBlock: Block
    
    var recentShapes: [Block.Shape] = []
    
    func generateNextBlock() -> Block {
        var shapes = Block.Shape.all
        for recent in recentShapes {
            let index = shapes.index(of: recent)!
            shapes.remove(at: index)
        }
        let shape = shapes.random()
        recentShapes.append(shape)
        let memory = 3
        let excess = recentShapes.count - memory
        if excess > 0 {
            recentShapes.removeFirst(excess)
        }
        dump(recentShapes)
        return Block(shape: shape, orientation: Block.Orientation.all.random())
    }
    
    func moveLeft() {
        if currentBlock.canMoveLeft(in: board) {
            currentBlock.moveLeft()
            callback?(.moveLeft)
        }
    }
    
    func moveRight() {
        if currentBlock.canMoveRight(in: board) {
            currentBlock.moveRight()
            callback?(.moveRight)
        }
    }
    
    func drop() {
        var distance = 0
        while currentBlock.isFalling && currentBlock.canFall(in: board) {
            currentBlock.fall()
            distance += 1
        }
        callback?(.drop(by: distance))
    }
    
    func rotate() {
        if currentBlock.rotate(in: board) {
            callback?(.rotate(by: 90))
        }
    }
    
    var board: Board
    func cellAt(x: Int, y: Int) -> Cell {
        return board.cell(at: Position(x: x, y: y))
    }
    
    enum Event {
        typealias Degrees = Int
        case startGame
        case newPiece
        case fall
        case drop(by: Int)
        case moveLeft
        case moveRight
        case rotate(by: Degrees)
        case completed(lines: IndexSet)
        case gameOver
    }
    typealias Callback = (Event) -> Void
    var callback: Callback?
    
}





