math.randomseed(os.time())
local Deck = require "Deck"
local Card = require "Card"
local insert = table.insert
local lg = love.graphics
local lm = love.mouse

local items = {}


local function makeDeck(jokers)
    local cards = {}
    local suits = {"Clubs", "Diamonds", "Hearts", "Spades"}
    local ranks = {"Ace", 2, 3, 4, 5, 6, 7, 8, 9, 10, "Jack", "Queen", "King"}

    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            insert(cards, Card(suit, rank))
        end
    end

    if jokers then
        insert(cards, Card("", "Joker"))
        insert(cards, Card("", "Joker"))
    end

    return Deck(cards)
end

function love.load()
    insert(items, makeDeck(true))
    items[1]:shuffleCards()
    items[1]:moveTo(lg.getWidth()/2, lg.getHeight()/2)
    items[2] = Card("", "Joker")
    items[2]:moveTo(100, 100)
    items[2]:flip()
end

local holding = false -- we might be holding something!

-- helper function to see if we are hovering over something
local function isOnItem(x, y, item)
    if (x > item.x - Card.static.width/2)
    and (x < item.x + Card.static.width/2)
    and (y > item.y - Card.static.height/2)
    and (y < item.y + Card.static.height/2) then
        return true
    else
        return false
    end
end

function love.draw()
    for i=1,#items do
        items[i]:draw()
    end
    --lg.line(lg.getWidth()/2, 0, lg.getWidth()/2, lg.getHeight())
    --lg.line(0, 0, lg.getWidth(), lg.getHeight())
    --lg.line(lg.getWidth(), 0, 0, lg.getHeight())

    if holding then
        --draw holding where the mouse is
        local x, y = lm.getPosition()
        holding:draw(nil, x, y) --nil face, draw however it is
    end

    --lg.print("Left click to move cards/decks, right click to flip a card (or all cards in a deck). Scroll to shuffle decks.", 2, lg.getHeight() - 14)

    --All cards in a deck are facing the same way automatically.
    if not holding then
        --not holading anything
        lg.print("Left click to grab a card or deck. Scroll over a deck to shuffle it. Right click to flip a card or the cards in a deck.", 2, lg.getHeight() - 14)
    else
        local hovering = false

        for i=#items,1,-1 do
            local x, y = lm.getPosition()
            if isOnItem(x, y, items[i]) then
                if items[i]:isInstanceOf(Card) then
                    hovering = "Card"
                else
                    hovering = "Deck"
                end
                break
            end
        end

        if holding:isInstanceOf(Card) then
            if hovering == "Card" then
                --card on card
                lg.print("Left click to form a deck with this card and the one under it. Right click to flip card.", 2, lg.getHeight() - 14)
            elseif hovering == "Deck" then
                --card on deck
                lg.print("Left click to shuffle it into the deck. Scroll up to place card on top of deck, scroll down to place card on bottom of deck. Right click to flip card.", 2, lg.getHeight() - 14)
            else
                --card over nothing
                lg.print("Left click to place card. Right click to flip card.", 2, lg.getHeight() - 14)
            end
        else
            if hovering == "Card" then
                --deck over card
                lg.print("Left click to place deck (will not shuffle card underneath into the deck). Right click to flip cards in the deck.", 2, lg.getHeight() - 14)
            elseif hovering == "Deck" then
                --deck over deck
                lg.print("Left click to place deck (will not interact with deck underneath). Scroll up to add this deck on top, scroll down to add this deck on bottom. Right click to flip cards in this deck.", 2, lg.getHeight() - 14)
            else
                --deck over nothing
                lg.print("Left click to place deck. Scroll to shuffle the deck. Right click to flip cards in the deck.", 2, lg.getHeight() - 14)
            end
        end
    end
end

function love.mousepressed(x, y, button)
    --[[ ORIGINAL TEXT, NOT ACCURATE
    Left click will grab a card or deck.
    While holding a card: Left click will place it (as long as the mouse is not over a deck).
    While holding a card over a deck: Scroll up to place it on top of the deck, scroll down to place it on the bottom of the deck. Right click to shuffle it into the deck.
    While holding a deck: Left click will place it (as long as the mouse is not over a deck).
    While holding a deck over a deck: Scroll up to place it on top of the deck, scroll down to place it on the bottom of the deck. Right click to shuffle the decks together.
    While NOT holding anything: Right click a card to flip it, or right click a deck to flip the cards in it (does not flip order of cards). Scroll over a deck to shuffle it.
    All cards in a deck are facing the same way automatically.
    --]]
    if button == "l" then
        if not holding then
            for i=#items,1,-1 do
                if isOnItem(x, y, items[i]) then
                    holding = table.remove(items, i)
                    break
                end
            end
        elseif holding:isInstanceOf(Deck) then
            holding:moveTo(x, y)
            insert(items, holding)
            holding = false
        elseif holding:isInstanceOf(Card) then --redundant checks woo
            local item = false

            for i=#items,1,-1 do
                if isOnItem(x, y, items[i]) then
                    item = i
                end
            end

            if not item then
                holding:moveTo(x, y)
                insert(items, holding)
                holding = false
            elseif items[item]:isInstanceOf(Card) then
                local card = table.remove(items, item)
                local deck = Deck({card, holding})
                insert(items, deck)
                holding = false
            elseif items[item]:isInstanceOf(Deck) then
                --TODO shuffle it into the deck
            end
        end
        --[[
                --card on deck
                "Scroll up to place card on top of deck, scroll down to place card on bottom of deck."

                --deck over deck
                "Scroll up to add this deck on top, scroll down to add this deck on bottom."
                --deck over nothing
                "Scroll to shuffle the deck."
        ]]
    elseif button == "wu" then --WU AND WD ARE ALMOST IDENTICAL, COLLAPSE THEM INTO ONE WHERE POSSIBLE
        if not holding then
            for i=#items,1,-1 do --ABSTRACT THIS FOR, I DO IT TOO MUCH ?
                if isOnItem(x, y, items[i]) and items[i]:isInstanceOf(Deck) then
                    items[i]:shuffleCards()
                    break
                end
            end
        elseif holding:isInstanceOf(Card) then
            --TODO easy
        elseif holding:isInstanceOf(Deck) then
            --TODO maybe harder
        end
    elseif button == "wd" then
        if not holding then
            for i=#items,1,-1 do
                if isOnItem(x, y, items[i]) and items[i]:isInstanceOf(Deck) then
                    items[i]:shuffleCards()
                    break
                end
            end
        elseif holding:isInstanceOf(Card) then
            --TODO easy
        elseif holding:isInstanceOf(Deck) then
            --TODO maybe harder
        end
    elseif button == "r" then
        if holding then
            holding:flip()
        else
            for i=#items,1,-1 do
                if isOnItem(x, y, items[i]) then
                    items[i]:flip()
                    break
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

-- ♣ ♦ ♥ ♠ A 2 3 4 5 6 7 8 9 10 J Q K Joker
