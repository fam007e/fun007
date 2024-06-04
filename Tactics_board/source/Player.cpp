#include "Player.hpp"

Player::Player() {
    shape.setRadius(10.0f);
    shape.setFillColor(sf::Color::Blue);
    shape.setOrigin(shape.getRadius(), shape.getRadius());
}

void Player::setPosition(const sf::Vector2f& position) {
    shape.setPosition(position);
}

void Player::draw(sf::RenderWindow& window) {
    window.draw(shape);
}

bool Player::contains(const sf::Vector2i& point) {
    sf::FloatRect bounds = shape.getGlobalBounds();
    return bounds.contains(static_cast<sf::Vector2f>(point));
}
