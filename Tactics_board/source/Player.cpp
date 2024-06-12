#include "Player.hpp"

Player::Player(const sf::Vector2f& position, const std::string& name, int number)
    : name(name), number(number) {
    shape.setRadius(10.0f);
    shape.setFillColor(sf::Color::Blue);
    shape.setPosition(position);

    if (!font.loadFromFile("../resources/fonts/arial.ttf")) {
        // Handle error
    }

    nameText.setFont(font);
    nameText.setString(name);
    nameText.setCharacterSize(12);
    nameText.setFillColor(sf::Color::White);
    nameText.setPosition(position.x, position.y - 20);

    numberText.setFont(font);
    numberText.setString(std::to_string(number));
    numberText.setCharacterSize(12);
    numberText.setFillColor(sf::Color::White);
    numberText.setPosition(position.x, position.y + 20);
}

void Player::draw(sf::RenderWindow& window) {
    window.draw(shape);
    window.draw(nameText);
    window.draw(numberText);
}

void Player::setPosition(const sf::Vector2f& position) {
    shape.setPosition(position);
    nameText.setPosition(position.x, position.y - 20);
    numberText.setPosition(position.x, position.y + 20);
}

bool Player::contains(const sf::Vector2i& point) const {
    return shape.getGlobalBounds().contains(static_cast<sf::Vector2f>(point));
}

const sf::Vector2f& Player::getPosition() const {
    return shape.getPosition();
}
