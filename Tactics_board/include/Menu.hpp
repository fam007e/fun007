#ifndef MENU_HPP
#define MENU_HPP

#include <SFML/Graphics.hpp>

class Menu {
public:
    Menu();
    void initialize(const sf::Vector2u& windowSize);
    void handleMouseClick(const sf::Vector2i& mousePos, bool& menuVisible, bool& dragging, int& selectedTool);
    void draw(sf::RenderWindow& window, bool menuVisible);

private:
    sf::Texture menuIconTexture;
    sf::Sprite menuIconSprite;

    sf::Texture closeIconTexture;
    sf::Sprite closeIconSprite;

    // Other icons and sprites for tools...

    bool isPointInSprite(const sf::Sprite& sprite, const sf::Vector2i& point);
};

#endif // MENU_HPP
