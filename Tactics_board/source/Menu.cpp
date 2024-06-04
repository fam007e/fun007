#include "Menu.hpp"
#include <iostream>

Menu::Menu() {
    if (!menuIconTexture.loadFromFile("../resources/icons/menu_icon.png")) {
        std::cerr << "Error loading menu icon texture" << std::endl;
    }
    menuIconSprite.setTexture(menuIconTexture);

    if (!closeIconTexture.loadFromFile("../resources/icons/close_icon.png")) {
        std::cerr << "Error loading close icon texture" << std::endl;
    }
    closeIconSprite.setTexture(closeIconTexture);
}

void Menu::initialize(const sf::Vector2u& windowSize) {
    float iconSize = windowSize.x * 0.05f; // 5% of the screen width
    menuIconSprite.setScale(iconSize / menuIconTexture.getSize().x, iconSize / menuIconTexture.getSize().y);
    menuIconSprite.setPosition(0.05f * windowSize.x, 0.05f * windowSize.y); // Top left corner

    closeIconSprite.setScale(iconSize / closeIconTexture.getSize().x, iconSize / closeIconTexture.getSize().y);
    closeIconSprite.setPosition(0.9f * windowSize.x, 0.05f * windowSize.y); // Top right corner
}

void Menu::handleMouseClick(const sf::Vector2i& mousePos, bool& menuVisible, bool& dragging, int& selectedTool) {
    if (isPointInSprite(menuIconSprite, mousePos)) {
        menuVisible = !menuVisible;
        std::cout << "Menu icon clicked" << std::endl;
    }
    if (menuVisible) {
        // Handle clicks on menu items
    }
    if (isPointInSprite(closeIconSprite, mousePos)) {
        // Handle close icon click if needed
    }
}

void Menu::draw(sf::RenderWindow& window, bool menuVisible) {
    window.draw(menuIconSprite);
    if (menuVisible) {
        window.draw(closeIconSprite);
        // Draw other menu items/icons
    }
}

bool Menu::isPointInSprite(const sf::Sprite& sprite, const sf::Vector2i& point) {
    sf::FloatRect bounds = sprite.getGlobalBounds();
    return bounds.contains(static_cast<sf::Vector2f>(point));
}
