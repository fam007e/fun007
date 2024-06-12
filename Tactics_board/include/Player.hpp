#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <SFML/Graphics.hpp>
#include <string>

class Player {
public:
    Player(const sf::Vector2f& position, const std::string& name, int number);

    void draw(sf::RenderWindow& window);
    void setPosition(const sf::Vector2f& position);
    bool contains(const sf::Vector2i& point) const;
    const sf::Vector2f& getPosition() const;

private:
    sf::CircleShape shape;
    sf::Text nameText;
    sf::Text numberText;
    sf::Font font;
    std::string name;
    int number;
};

#endif // PLAYER_HPP
