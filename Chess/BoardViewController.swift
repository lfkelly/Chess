//
//  BoardViewController.swift
//  Chess
//
//  Created by Liam Kelly on 3/6/17.
//  Copyright © 2017 LiamKelly. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController {
    
    //TODO: Add a 'lost pieces' view
    //TODO: Add move history
    //TODO: Add 'undo'
    
    var alreadyToggled:Bool = false
    var board:Board = Board()
    let moves:Moves = Moves()
    var selectedPiece:Board.Piece = Board.Piece()
    var selectedButton:UIButton = UIButton()
    
    var possibleMoveLocations:[UIButton] = [UIButton]()
    var piecesOnBoard:[UIButton] = [UIButton]()
    
    var blackButtons:[UIButton] = [UIButton]()
    var whiteButtons:[UIButton] = [UIButton]()
    
    var blackTurn:Bool = true
    
    @IBOutlet weak var boardView:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        board.boardSetup()
        createBoard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // create the dimensions and starting point for the board
    func createBoard() {

        //Set up dimensions and origin of board, add 'remove highlights' if board is tapped
        let sideLength = self.view.frame.width
        let startingPoint = (self.view.frame.height - sideLength)/2
        boardView.frame.size.width = sideLength
        boardView.frame.size.height = sideLength
        boardView.frame.origin = CGPoint(x: 0, y: startingPoint)
        boardView.image = UIImage(named: "Board")
        boardView.isUserInteractionEnabled = true
        let tapOnBoard = UITapGestureRecognizer(target: self, action: #selector(toggleOffOptions))
        boardView.addGestureRecognizer(tapOnBoard)
        
        //Set up array of space positions for board
        board.attachSpaceLocations(startingPoint: boardView.frame.origin, width: sideLength)
        
        var row = 0
        var col = 0
        for Row in board.board {
            for space in Row {
                // Add 'tapped on piece' function to each button
                if(space.isOccupied) {
                    let button = UIButton()
                    let assetName = space.piece.color + space.piece.type
                    button.addTarget(self, action: #selector(tappedOnPiece(sender:)), for: UIControlEvents.touchUpInside)
                    button.frame = getSquareForScreen(pos: [row,col])
                    button.setImage(UIImage(named: assetName), for: UIControlState())
                    piecesOnBoard.append(button)
                    if(space.piece.color == "White") {
                        whiteButtons.append(button)
                    } else {
                        blackButtons.append(button)
                    }
                    view.addSubview(button)
                }
                col+=1
            }
            col = 0
            row+=1
        }
        
        // turn off black buttons for first move of the game
        disableBlackButtons()
    }
    
    
    func getSquareForScreen(pos:[Int]) -> CGRect {
        let side = self.view.frame.width / 8
        let size = CGSize(width: side, height: side)
        let rect = CGRect(origin: board.getXYForPos(pos: pos), size: size)
        return rect
    }
    
    func tappedOnPiece(sender:UIButton) {
        let pieceOrigin = sender.frame.origin
        let piece = board.getPieceByLocation(location: pieceOrigin)
        selectedPiece = piece
        selectedButton = sender
        
        if(alreadyToggled == true) {
            toggleOffOptions()
        }
        toggleOptionsForPiece(piece: piece)
        alreadyToggled = true
    }
    
    
    func toggleOptionsForPiece(piece:Board.Piece) {
        // create squares to highlight, add them to possibleMoveLocation array, make them playable
        let coordinatesToHighlight = moves.movesForPiece(boardObject: board, piece: piece, position: piece.currentPos)
        for rc in coordinatesToHighlight {
            createHighlightForPos(pos: rc)
        }
    }
    
    // Removes all highlighted options from superview, deletes the contents of the highlightedmove array
    func toggleOffOptions() {
        for option in possibleMoveLocations {
            option.removeFromSuperview()
        }
        possibleMoveLocations.removeAll()
    }
    

    // Adds a clickable button to move a piece to
    func createHighlightForPos(pos:[Int]) {
        let rect = getSquareForScreen(pos: pos)
        let highlightedButton = UIButton(frame: rect)
        highlightedButton.setImage(UIImage(named: "Option"), for: UIControlState())

        highlightedButton.addTarget(self, action: #selector(choseHighlightedSpace(sender:)), for: UIControlEvents.touchUpInside)
        possibleMoveLocations.append(highlightedButton)
        view.addSubview(highlightedButton)
    }
    
    
    
    // attached to the highlighted spaces, updates board state and animates piece moving
    func choseHighlightedSpace(sender:UIButton) {
        toggleOffOptions()
        disableButtonsForTurn()
        let endOrigin:CGPoint = sender.frame.origin
        let endPos:[Int] = board.getRCforXY(location: endOrigin)
        let pieceTaken = board.getPieceByLocation(location: endOrigin)

        if board.getPieceByLocation(location: endOrigin).type != "" {
            for button in piecesOnBoard {
                if button.frame.origin == endOrigin {
                    button.removeFromSuperview()
                }
            }
        }
        
        if moves.enPessent {
            
        }
        
        if(selectedPiece.type == "Pawn") {
            checkForEnPessent(piece: selectedPiece, board: board, moves: moves, to: endPos)
        }
        // updates board state
        selectedPiece.button.frame.origin = CGPoint(x: CGFloat(300), y: CGFloat(300))
        board.movePiece(piece: selectedPiece, to: endPos)
        print("===================")
        board.printBoard()
        print("===================")
        UIView.animate(withDuration: 0.5) { 
            self.selectedButton.frame.origin = self.board.getXYForPos(pos: endPos)
        }
        
        if(pieceTaken.type == "King") {
            endGame(color:pieceTaken.color)
        }
    }

    // disables interaction with buttons if it's not that color's turn
    func disableButtonsForTurn() {
        if blackTurn {
            enableBlackButtons()
            disableWhiteButtons()
            blackTurn = false
        } else {
            disableBlackButtons()
            enableWhiteButtons()
            blackTurn = true
        }
    }
    
    // Check if the move was an en pessent
    func checkForEnPessent( piece:Board.Piece, board:Board, moves:Moves, to:[Int]) {
        if (piece.color == "White") {
            if piece.currentPos == [to[0] + 2, to[1]] {
                moves.enPessent = true
                moves.enPessentColor = "White"
                moves.enPessentPos = [to[0] + 1, to[1]]
            }
        } else if piece.currentPos == [to[0] - 2, to[1]] {
            moves.enPessent = true
            moves.enPessentColor = "Black"
            moves.enPessentPos = [to[0] - 1, to[1]]
            
        } else {
            moves.enPessent = false
        }
    }
    
    
    func endGame(color:String) {
        disableBlackButtons()
        disableWhiteButtons()
        if(color == "Black") {
            //white wins
        } else {
            //black wins
        }
    }
    
    func disableBlackButtons() {
        for button in blackButtons {
            button.isUserInteractionEnabled = false
        }
    }
    
    func disableWhiteButtons() {
        for button in whiteButtons {
            button.isUserInteractionEnabled = false
        }
    }
    
    func enableBlackButtons() {
        for button in blackButtons {
            button.isUserInteractionEnabled = true
        }
    }
    
    func enableWhiteButtons() {
        for button in whiteButtons {
            button.isUserInteractionEnabled = true
        }
    }
    
}

