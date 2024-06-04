#include "TacticsBoard.hpp"
#include <iostream>

TacticsBoard::TacticsBoard() 
    : menuVisible(false), dragging(false), selectedPlayer(nullptr), selectedTool(-1) {
    if (!pitchTexture.loadFromFile("../resources/pitches/football_pitch.png")) {
        std::cerr << "Error loading football pitch texture" << std::endl;
    }
    pitchSprite.setTexture(pitchTexture);
    pitchSprite.setScale(
        float(WINDOW_WIDTH) / pitchTexture.getSize().x,
        float(WINDOW_HEIGHT) / pitchTexture.getSize().y
    );

    menu.initialize(sf::Vector2u(WINDOW_WIDTH, WINDOW_HEIGHT));

    // Initialize players
    int numPlayersPerTeam = 11; // Assuming 11 players per team
    float fieldWidth = WINDOW_WIDTH; // Width of the window
    float fieldHeight = WINDOW_HEIGHT; // Height of the window
    float playerRadius = 10.0f; // Radius of each player circle

    // Initialize team 1 players (left side)
    float startX = fieldWidth * 0.1f; // Start position from left edge
    float startY = fieldHeight / 2 - (numPlayersPerTeam / 2 * playerRadius * 2); // Center vertically

    for (int i = 0; i < numPlayersPerTeam; ++i) {
        players.emplace_back(sf::Vector2f(startX + i * (playerRadius * 2), startY + i * (playerRadius * 2)));
    }

    // Initialize team 2 players (right side)
    startX = fieldWidth * 0.9f; // Start position from right edge
    startY = fieldHeight / 2 - (numPlayersPerTeam / 2 * playerRadius * 2); // Center vertically

    for (int i = 0; i < numPlayersPerTeam; ++i) {
        players.emplace_back(sf::Vector2f(startX - i * (playerRadius * 2), startY + i * (playerRadius * 2)));
    }
}

void TacticsBoard::run() {
    sf::RenderWindow window(sf::VideoMode(WINDOW_WIDTH, WINDOW_HEIGHT), "Tactics Board", sf::Style::Fullscreen);
    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
            handleMouseEvent(event, window);
        }

        update();

        window.clear();
        render(window);
        window.display();
    }
}

void TacticsBoard::handleMouseEvent(sf::Event& event, sf::RenderWindow& window) {
    if (event.type == sf::Event::MouseButtonPressed) {
        if (event.mouseButton.button == sf::Mouse::Left) {
            sf::Vector2i mousePos = sf::Mouse::getPosition(window);
            menu.handleMouseClick(mousePos, menuVisible, dragging, selectedTool);
            if (!menuVisible) {
                for (auto& player : players) {
                    if (player.contains(mousePos)) {
                        dragging = true;
                        selectedPlayer = &player;
                        oldMousePosition = window.mapPixelToCoords(mousePos);
                        break;
                    }
                }
            }
        }
    } else if (event.type == sf::Event::MouseButtonReleased) {
        if (event.mouseButton.button == sf::Mouse::Left) {
            dragging = false;
            selectedPlayer = nullptr;
        }
    } else if (event.type == sf::Event::MouseMoved) {
        if (dragging && selectedPlayer != nullptr) {
            sf::Vector2i mousePos = sf::Mouse::getPosition(window);
            sf::Vector2f newMousePosition = window.mapPixelToCoords(mousePos);
            selectedPlayer->setPosition(newMousePosition);
        }
    }
}

void TacticsBoard::update() {
    // Update logic
}

void TacticsBoard::render(sf::RenderWindow& window) {
    window.draw(pitchSprite);
    for (auto& player : players) {
        player.draw(window);
    }
    menu.draw(window, menuVisible);
}
