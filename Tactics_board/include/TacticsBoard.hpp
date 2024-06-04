#ifndef TACTICSBOARD_HPP
#define TACTICSBOARD_HPP

#include <SFML/Graphics.hpp>
#include <vector>
#include "Player.hpp"
#include "Menu.hpp"

class TacticsBoard {
public:
    TacticsBoard();

    void run();

private:
    sf::Texture pitchTexture;
    sf::Sprite pitchSprite;

    std::vector<Player> players; // Add this line
    bool menuVisible; // Add this line
    bool dragging; // Add this line
    Player* selectedPlayer; // Add this line
    int selectedTool; // Add this line

    Menu menu;

    void handleMouseEvent(sf::Event& event, sf::RenderWindow& window);
    void update();
    void render(sf::RenderWindow& window);
};

#endif // TACTICSBOARD_HPP
