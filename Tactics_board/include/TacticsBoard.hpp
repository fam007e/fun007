#ifndef TACTICSBOARD_HPP
#define TACTICSBOARD_HPP

#include <SFML/Graphics.hpp>
#include <vector>
#include "Menu.hpp"
#include "Player.hpp"

const unsigned int WINDOW_WIDTH = 1280;
const unsigned int WINDOW_HEIGHT = 720;

class TacticsBoard {
public:
    TacticsBoard();
    void run();

private:
    void handleMouseEvent(sf::Event& event, sf::RenderWindow& window);
    void update();
    void render(sf::RenderWindow& window);

    sf::Texture pitchTexture;
    sf::Sprite pitchSprite;

    std::vector<Player> players;
    Menu menu;

    bool menuVisible;
    bool dragging;
    Player* selectedPlayer;
    sf::Vector2f oldMousePosition;
    int selectedTool;
};

#endif // TACTICSBOARD_HPP
