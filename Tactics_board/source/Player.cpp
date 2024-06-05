#include "Player.hpp"

Player::Player(const sf::Vector2f& position) {
    shape.setRadius(10.0f);
    shape.setFillColor(sf::Color::Red);
    shape.setPosition(position);
}

void Player::draw(sf::RenderWindow& window) const {
    window.draw(shape);
}

sf::Vector2f Player::getPosition() const {
    return shape.getPosition();
}

void Player::setPosition(const sf::Vector2f& position) { // Add this method
    shape.setPosition(position);
}

bool Player::contains(const sf::Vector2i& point) const { // Add this method
    sf::FloatRect bounds = shape.getGlobalBounds();
    return bounds.contains(static_cast<sf::Vector2f>(point));
}
