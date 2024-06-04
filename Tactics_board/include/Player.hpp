#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <SFML/Graphics.hpp>

class Player {
public:
    Player();
    void setPosition(const sf::Vector2f& position);
    void draw(sf::RenderWindow& window);
    bool contains(const sf::Vector2i& point);

private:
    sf::CircleShape shape;
};

#endif // PLAYER_HPP
