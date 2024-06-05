#include "Menu.hpp"
#include <iostream>

Menu::Menu() {
    // Preload icons with file paths
    std::vector<std::string> iconFilepaths = {
        "../resources/icons/menu_icon.png",
        "../resources/icons/close_icon.png",
        "../resources/icons/arrow_icon.png",
        "../resources/icons/line_icon.png",
        "../resources/icons/eraser_icon.png",
        "../resources/icons/oval_icon.png",
        "../resources/icons/rectangle_icon.png",
        "../resources/icons/playerlist_icon.png"
    };

    // Load textures and create sprites
    for (const auto& filepath : iconFilepaths) {
        Icon icon;
        if (!icon.texture.loadFromFile(filepath)) {
            std::cerr << "Error loading texture: " << filepath << std::endl;
        }
        icon.sprite.setTexture(icon.texture);
        icons.push_back(icon);
    }
}

void Menu::generateShadow(Icon& icon) {
    // Create a new image for the shadow based on the original texture
    sf::Image image = icon.texture.copyToImage();
    sf::Image shadowImage;
    shadowImage.create(image.getSize().x, image.getSize().y, sf::Color(0, 0, 0, 0));

    // Process each pixel to create a shadow
    for (unsigned y = 0; y < image.getSize().y; ++y) {
        for (unsigned x = 0; x < image.getSize().x; ++x) {
            sf::Color color = image.getPixel(x, y);
            if (color.a > 0) {  // Only shadow non-transparent pixels
                shadowImage.setPixel(x, y, sf::Color(0, 0, 0, 100)); // Semi-transparent black
            }
        }
    }

    // Load the modified image into the shadow texture
    sf::Texture shadowTexture;
    shadowTexture.loadFromImage(shadowImage);
    icon.shadow.setTexture(shadowTexture);
    icon.shadow.setScale(icon.sprite.getScale());
    icon.shadow.setPosition(icon.sprite.getPosition() + sf::Vector2f(5, 5)); // Offset position for shadow
}

void Menu::initialize(const sf::Vector2u& windowSize) {
    // Define sizes and positions
    float menuIconSize = windowSize.x * 0.045f;
    float closeIconSize = windowSize.x * 0.036f;
    float toolIconSize = windowSize.x * 0.02f;
    float startY = 0.12f * windowSize.y;
    float spacing = toolIconSize * 1.2f;

    // Initialize icons with scales and positions
    initializeIcon(icons[0], "../resources/icons/menu_icon.png", menuIconSize, {0.02f * windowSize.x, 0.02f * windowSize.y});
    initializeIcon(icons[1], "../resources/icons/close_icon.png", closeIconSize, {0.98f * windowSize.x - icons[1].sprite.getGlobalBounds().width, 0.02f * windowSize.y});

    for (size_t i = 2; i < icons.size(); ++i) {
        initializeIcon(icons[i], "", toolIconSize, {0.02f * windowSize.x, startY + (i - 2) * spacing});
    }
}

void Menu::initializeIcon(Icon& icon, const std::string& filepath, float scale, const sf::Vector2f& position) {
    if (!filepath.empty()) {
        icon.texture.loadFromFile(filepath);
    }
    icon.sprite.setScale(scale / icon.texture.getSize().x, scale / icon.texture.getSize().y);
    icon.sprite.setPosition(position);
    generateShadow(icon);  // Generate shadow for the icon
}

void Menu::handleMouseClick(const sf::Vector2i& mousePos, bool& menuVisible, bool& dragging, int& selectedTool) {
    if (isPointInSprite(icons[0].sprite, mousePos)) {
        menuVisible = !menuVisible;
        std::cout << "Menu icon clicked" << std::endl;
    }

    if (menuVisible) {
        for (size_t i = 2; i < icons.size(); ++i) {
            if (isPointInSprite(icons[i].sprite, mousePos)) {
                selectedTool = static_cast<int>(i - 2);
                break;
            }
        }
    }
}

void Menu::draw(sf::RenderWindow& window, bool menuVisible) {
    // Always draw the menu and close icons
    window.draw(icons[0].shadow);
    window.draw(icons[0].sprite);
    window.draw(icons[1].shadow);
    window.draw(icons[1].sprite);

    if (menuVisible) {
        for (size_t i = 2; i < icons.size(); ++i) {
            window.draw(icons[i].shadow);
            window.draw(icons[i].sprite);
        }
    }
}

bool Menu::isPointInSprite(const sf::Sprite& sprite, const sf::Vector2i& point) {
    sf::FloatRect bounds = sprite.getGlobalBounds();
    return bounds.contains(static_cast<sf::Vector2f>(point));
}
