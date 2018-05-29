//
//  GameScene.swift
//  DragAndDrop
//
//  Created by Andrew Obukhov on 24/05/2018.
//  Copyright © 2018 Andrew Obukhov. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    private var player : SKSpriteNode?
    
    private var boxes = [SKSpriteNode]()
    
    private var movableNode : SKNode?
    
    private var currentLetter = ""
    
    private var letters = ["Э", "И", "У", "Ы", "А", "О", ""]
    
    private let successPhrases = ["Молодец", "У тебя хорошо получается"]
    
    private let faildPhrases =  ["Ошибочка", "Ой, Не туда!"]
    
    private let boxSize = CGSize(width: 88, height: 66)
    
    override func didMove(to view: SKView) {
        generatePlayer()
        generateBoxes()
        
        shuffleLetters()
        reinit()
    }
    
    func speakPhrase(phrases: [String]) {
        speak(text: phrases[GKRandomSource.sharedRandom().nextInt(upperBound: phrases.count)])
    }
    
    func generatePlayer() {
        guard let player = self.childNode(withName: "player") as? SKSpriteNode else {return}
        
        self.player = player
        player.zPosition = 20
        
        let shift: CGFloat = 15
        
        let sequence =  [SKAction.moveBy(x: shift, y: shift, duration: 1),
                         SKAction.moveBy(x: shift*2, y: -shift, duration: 1),
                         SKAction.moveBy(x: -shift * 3, y: 0, duration: 1)]
        
        player.run(SKAction.repeatForever(SKAction.sequence(sequence)))
        
        speak(text: "Привет! Я дракон - Гена. Давай играть!")
    }
    
    func generateBoxes() {
        let count = letters.count
        let width = Int(self.size.width)
        
        let shift = (width - (Int(boxSize.width) * count)) / count
        let staticShift = 5
        
        for i in 0 ..< count {
            let x = i * (Int(boxSize.width) + shift) + staticShift
            let size = CGSize(width: boxSize.width, height: boxSize.height)
            let pos = CGPoint(x: x, y: 2)
            let box = generateBox(letter: letters[i], size: size, position: pos)
            self.boxes.append(box)
        }
    }
    
    func generateBox(letter: String, size: CGSize, position: CGPoint) -> SKSpriteNode {
        let box = SKSpriteNode(imageNamed: "box")
        box.name = "box"
        box.anchorPoint = CGPoint(x: 0, y: 0)
        box.size = size
        box.position = position
        box.color = .cyan
        box.zPosition = 10
        
        let later = addLetter(letter: letter, position: CGPoint(x: size.width / 2 - 3, y: size.height / 2 - 10))
        box.addChild(later)
        
        self.addChild(box)
        return box
    }
    
    func addLetter(letter: String, position: CGPoint) -> SKLabelNode {
        let letter = SKLabelNode(text: letter)
        letter.name = "letter"
        letter.fontSize = 23
        letter.fontName = "Arial Bold"
        letter.fontColor = .red
        letter.position = position
        letter.zPosition = 1
        return letter
    }
    
    func shuffleLetters() {
        let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: self.letters)
        
        for (index, box) in boxes.enumerated() {
            if let letter = box.childNode(withName: "letter") as? SKLabelNode {
                letter.text = shuffled[index] as? String
                letter.fontColor = .red
            }
        }
    }
    
    func reinit() {
        setNewCurrentLetter()
        setInitPlayerPosition()
    }
    
    func setNewCurrentLetter() {
        self.currentLetter = self.letters[GKRandomSource.sharedRandom().nextInt(upperBound: self.letters.count)]
    }
    
    func setInitPlayerPosition() {
        player?.position = CGPoint(x: self.size.width / 2 - 30, y: self.size.height / 2 + 100)
    }
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text + "!")
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RUS")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.pauseSpeaking(at: .word)
        synthesizer.speak(utterance)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            if self.player!.contains(location) {
                speak(text: currentLetter)
                movableNode = self.player
                movableNode!.position = location
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, movableNode != nil {
            movableNode!.position = touch.location(in: self)
            let location = touch.location(in: self)
            
            for box in boxes {
                if let letter = box.childNode(withName: "letter") as? SKLabelNode {
                    if box.contains(location) {
                        letter.fontColor = .green
                    }
                    else{
                        letter.fontColor = .red
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, movableNode != nil {
            movableNode!.position = touch.location(in: self)
            movableNode = nil
            
            let location = touch.location(in: self)
            
            if let box = boxes.first(where: {$0.contains(location)}) {
                if let letter = box.childNode(withName: "letter") as? SKLabelNode {
                    
                    if letter.text == currentLetter {
                        speakPhrase(phrases: successPhrases)
                    }
                    else{
                        speakPhrase(phrases: faildPhrases)
                    }
                    
                    reinit()
                }
            } else {
                setInitPlayerPosition()
            }
            
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        movableNode = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
