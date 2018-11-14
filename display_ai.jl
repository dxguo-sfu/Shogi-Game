using Gtk.ShortNames, Graphics
using DataFrames
using SQLite

include("move_helpers.jl")
include("game_init.jl")
include("move.jl")
include("validate_alone.jl")
include("types.jl")
include("win.jl")


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end


function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function movePieceGUI(sx,sy,tx,ty)
    global board
    global window
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyImage)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyImage)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global sente_time
    global gote_time
    #global board
    global diff
    global user
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
        makeMove(db,thisMove)
         if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)
            push!(allBoards,duplicateBoard(board))
            if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
            makeMove(db,thisMove)
             if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if diff=="normal"
        tic()
        board1, timeTaken ,aiMove= AI_normal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="hard"
        tic()
        board1, timeTaken ,aiMove= AI_hard(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="protracted"
        tic()
        board1, timeTaken ,aiMove= AI_protracted(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="suicidal"
        tic()
        board1, timeTaken ,aiMove= AI_suicidal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    else 
        tic()
        board1, timeTaken ,aiMove= AI_random(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    end

    if moveNum%2==1
        if !(aiMove.sourcex in sente_promo_range) && ((aiMove.targetx in sente_promo_range) || (aiMove.targetx2 in sente_promo_range) || (aiMove.targetx3 in sente_promo_range))
            aiMove.option="!"
        end
    else
        if !(aiMove.sourcex in gote_promo_range) && ((aiMove.targetx in gote_promo_range) || (aiMove.targetx2 in gote_promo_range) || (aiMove.targetx3 in gote_promo_range))
            aiMove.option="!"
        end
    end
    makeMove(db,aiMove)
    if aiMove.move_type=="move"
        board[aiMove.targety][aiMove.targetx]=board[aiMove.sourcey][aiMove.sourcex]
        board[aiMove.targety][aiMove.targetx]=checkPromote(board[aiMove.targety][aiMove.targetx],moveNum,aiMove.targetx)
        board[aiMove.sourcey][aiMove.sourcex]=empty
        board=demon_burning(board)
        movePieceGUI(aiMove.sourcex,aiMove.sourcey,aiMove.targetx,aiMove.targety)
    end
     if checkWin(aiMove.move_type,isTimed,sente_time,gote_time,allBoards)
            #println("checking time")
            return
    end
    moveNum+=1
    init_buttons(user)
end


function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            try
                signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],(id2Arr[a][1]))
            catch e
                signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],Int64(id2Arr[a][1]))
            end
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            try
                signal_handler_block(grid[idArr[b][2],idArr[b][3]],(idArr[b][1]))
            catch e
                signal_handler_block(grid[idArr[b][2],idArr[b][3]],Int64(idArr[b][1]))
            end
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        #println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        #println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end

function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end






function display_ai(ofType,limit,add,japRoulette,ifFirst,cheatingAllowed,difficulty,colorBoard)

    global gameType=ofType
    global timeLimit=limit
    global timeAdd=add
    global jRoulette=japRoulette
    global goFirst=ifFirst
    global cheating=cheatingAllowed
    global diff=difficulty
    global color=colorBoard
    global sente_time=timeLimit
    global gote_time=timeLimit
    global allBoards=[]
    if timeLimit > 0
        global isTimed=true
    else 
        global isTimed=false
    end


    global grid = @Grid()
    global window = @Window("Shogi by null_ptr")
    global emptyImage=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
    global moveNum=1
    global double=["lion","falcon","soaring"]
    global triple=["demon","vice","great","tetrarch"]
    global sente=[]
    global gote=[]
    global idArr=[]
    global id2Arr=[]
    global prevsx=0
    global prevsy=0
    global prevtx=0
    global prevty=0
    global userMove=[]
    global DF=0

    global fileName="gameplay.db"
    filePath=joinpath(pwd(),fileName)
    chmod(filePath,0o777,recursive=true)
    touch(filePath)
    rm(filePath,recursive=false,force=true)


    if diff=="normal"
        include("move_normal.jl")
    elseif diff=="hard"
        include("move_hard.jl")
    elseif diff=="protracted"
        include("move_protracted")
    elseif diff=="suicidal"
        include("move_suicidal.jl")
    else 
        include("move_random.jl")
    end

    if gameType=="standard"
        gameTypeFile="S"
        global N=9
    elseif gameType=="chu"
        gameTypeFile="C"
        global N=12
    elseif gameType=="mini"
        gameTypeFile="M"
        global N=5
    else
        gameTypeFile="T"
        global N=16
    end


    global empty=piece("", "", 0, 0, -1, false)

    global board = [ [ empty for i = 1:N ] for j = 1:N ]


    global pieceArr=[]

    global db=gameFileSetup(fileName,gameTypeFile,cheating,timeLimit,timeAdd)

    global sente_promo_range
    global gote_promo_range

    if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16

        # sente/black/odd pieces
        push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
        push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 16, 9, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
        push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
        push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
        push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
        push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
        push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
        push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
        push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
        push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
        push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
        push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
        push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
        push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
        push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
        push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
        push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
        push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
        push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
        push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
        push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
        push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
        push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
        push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
        push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
        push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
        push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
        push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

    elseif gameType == "chu" # game setup for chu shogi
        sente_promo_range=1:4
        gote_promo_range=9:12

        # sente/black/odd pieces
        push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
        push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
        push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
        push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
        push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
        push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
        push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 12, 7, 1, false))
        push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
        push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
        push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
        push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
        push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
        push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
        push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 6, 0, false))
        push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
        push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
        push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

    elseif gameType == "standard" # game setup for standard shogi
        sente_promo_range=1:3
        gote_promo_range=7:9
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
        push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
        push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
        push!(pieceArr,piece("king", "king", 9, 5, 1, false))
        push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
        push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 5, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

    else # game setup for minishogi
        sente_promo_range=1:1
        gote_promo_range=5:5
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
        push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
        push!(pieceArr,piece("king", "king", 5, 5, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
        push!(pieceArr,piece("king", "king", 1, 1, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
        push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

    end


    for p in pieceArr
        if p.x!=-1
            board[p.y][p.x]=p
        end
    end

    push!(allBoards,duplicateBoard(board))

    for p in pieceArr
        if p.side==0
            push!(gote,p)
        else
            push!(sente,p)
        end
    end

    global user="sente"


    reset()
    setBoardGUI()
    if goFirst
        println("user")
        init_buttons(user)
    else
        if diff=="normal"
            tic()
            board, timeTaken ,aiMove= AI_normal(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="hard"
            tic()
            board, timeTaken ,aiMove= AI_hard(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="protracted"
            tic()
            board, timeTaken ,aiMove= AI_protracted(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="suicidal"
            tic()
            board, timeTaken ,aiMove= AI_suicidal(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        else 
            tic()
            board, timeTaken ,aiMove= AI_random(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        end
        makeMove(db,aiMove)
        if aiMove.move_type=="move"
            movePieceGUI(aiMove.sourcex,aiMove.sourcey,aiMove.targetx,aiMove.targety)
        end
        if  checkWin(aiMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return 
        end
        moveNum+=1
        user="gote"
        init_buttons(user)
    end

    push!(window,grid)
    showall(window)



    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
    end
end



