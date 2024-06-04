#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <SFML/Graphics.hpp>

class Player {
public:
    Player(const sf::Vector2f& position);

    void draw(sf::RenderWindow& window) const;
    sf::Vector2f getPosition() const;

private:
    sf::CircleShape shape;
};

#endif // PLAYER_HPP
