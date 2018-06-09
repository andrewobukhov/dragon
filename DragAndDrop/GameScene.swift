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
    
    private var capitan : SKSpriteNode?
    
    private var grounds = [SKSpriteNode]()
    
    private var currentLetter = ""
    
    private var knownLetters = [String]()
    
    private var letters = [String]()
    
    private let successPhrases = ["Молодец", "У тебя хорошо получается"]
    
    private let faildPhrases =  ["Ошибочка", "Ой, Не туда!"]
    
    override func didMove(to view: SKView) {
        initCapitan()
        initGrounds()
      
        shuffleLetters()
        //reinit()
    }
    
    func initCapitan() {
        guard let capitan = self.childNode(withName: "capitan") as? SKSpriteNode else {return}
        self.capitan = capitan
        
        //moveCapitan(location: CGPoint(x: 400, y: 200), moveDuration: 3)
    }
    
    func moveGround(node: SKSpriteNode, shift: CGFloat, duration: TimeInterval) {
        let sequence =  [SKAction.moveBy(x: 0, y: shift, duration: duration),
                         SKAction.moveBy(x: 0, y: -shift, duration: duration)]
        
        node.run(SKAction.repeatForever(SKAction.sequence(sequence)))
    }
    
    func speakPhrase(phrases: [String]) {
        speak(text: phrases[GKRandomSource.sharedRandom().nextInt(upperBound: phrases.count)])
    }
    
    func initGrounds() {
        for i in 0 ..< 4 {
            if let g = self.childNode(withName: "ground\(i + 1)") as? SKSpriteNode {
                moveGround(node: g, shift: 50, duration: (Double(i) / 2.0) + 1)
                grounds.append(g)
            }
        }
    }
    
    func moveCapitan(x: CGFloat, moveDuration: TimeInterval) {
        if capitan?.action(forKey: "walk") == nil {
            let animation = SKAction.repeatForever(SKAction.animate(with: getTexturesByAtlas("walk"), timePerFrame: 0.1))
            capitan?.run(animation, withKey: "walk")
        }
        
        let moveAction = SKAction.moveTo(x: x, duration: moveDuration)
        
        let doneAction = SKAction.run({ [weak self] in
            self?.capitan?.removeAllActions()
        })
        
        let moveActionWithDone = SKAction.sequence([moveAction, doneAction])
        capitan?.run(moveActionWithDone, withKey: "capitanMoving")
    }
    
    
    func getTexturesByAtlas(_ atlasName: String) -> [SKTexture] {
       let atlas = SKTextureAtlas(named: atlasName)
       return atlas.textureNames.sorted().map { name in atlas.textureNamed(name) }
    }
    
    func shuffleLetters() {
        let allLetters = ["Э", "И", "У", "Ы", "А", "О"]
        
        let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: allLetters).prefix(grounds.count)
    
        for (index, node) in grounds.enumerated() {
            if let letter = node.childNode(withName: "letter") as? SKLabelNode {
                letter.text = shuffled[index] as? String
                self.letters.append(letter.text!)
                 print(letter.text!, self.letters)
            }
        }
        
        setNewCurrentLetter()
    }
    
    func setNewCurrentLetter() {
        let letters = self.letters.filter { !knownLetters.contains($0) }
        
        if(!letters.isEmpty){
            self.currentLetter = letters[GKRandomSource.sharedRandom().nextInt(upperBound: letters.count)]
        }
    }
    
    let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text + "!")
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RUS")
        
        //let synthesizer = AVSpeechSynthesizer()
        synthesizer.pauseSpeaking(at: .word)
        synthesizer.speak(utterance)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            let ground = self.grounds.first {$0.contains(location)}
            
            if self.capitan!.contains(location) {
                speak(text: currentLetter)
            } else if let groundNode = ground {
                guard let letterNode = groundNode.childNode(withName: "letter") as? SKLabelNode else {return}
                
                if letterNode.text == currentLetter {
                    foundLetter(groundNode, letterNode: letterNode)
                } else if letterNode.text != nil {
                    speak(text: "Ошибка")
                }
            }
        }
    }
    
    func foundLetter(_ ground: SKSpriteNode, letterNode: SKLabelNode) {
        speak(text: "Молодец")
        ground.removeAllActions();
        letterNode.text = nil
    
        ground.run(SKAction.moveTo(y: CGFloat(55), duration: 1))
        self.knownLetters.append(currentLetter)
        
        if(self.knownLetters.count >= self.letters.count){
            moveCapitan(x: 500, moveDuration: 3)
        }
    
        setNewCurrentLetter()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
