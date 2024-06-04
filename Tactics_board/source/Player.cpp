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
