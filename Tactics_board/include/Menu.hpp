#ifndef MENU_HPP
#define MENU_HPP

#include <SFML/Graphics.hpp>
#include <vector>
#include <string>

class Menu {
public:
    struct Icon {
        sf::Texture texture;
        sf::Sprite sprite;
        sf::Sprite shadow;  // Add shadow sprite
    };

    Menu();
    void initialize(const sf::Vector2u& windowSize);
    void handleMouseClick(const sf::Vector2i& mousePos, bool& menuVisible, bool& dragging, int& selectedTool);
    void draw(sf::RenderWindow& window, bool menuVisible);
    bool isPointInSprite(const sf::Sprite& sprite, const sf::Vector2i& point);

private:
    std::vector<Icon> icons;
    void initializeIcon(Icon& icon, const std::string& filepath, float scale, const sf::Vector2f& position);
    void generateShadow(Icon& icon);  // Declare the shadow generation method
};

#endif // MENU_HPP
