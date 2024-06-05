#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <SFML/Graphics.hpp>

class Player {
public:
    Player(const sf::Vector2f& position);

    void draw(sf::RenderWindow& window) const;
    sf::Vector2f getPosition() const;
    void setPosition(const sf::Vector2f& position); // Add this line
    bool contains(const sf::Vector2i& point) const; // Add this line

private:
    sf::CircleShape shape;
};

#endif // PLAYER_HPP
