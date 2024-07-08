## [Unreleased]

## [0.9.0] - 2024-07-08

- Add object.replace method which uses PUT which performs a complete object replacement

### Breaking
- Change the object.update method to use PATCH which only performs a partial update(previously performed a replacement)

## [0.8.11] - 2024-07-02
- Allow the user to specify any options they want for multi-tenancy when creating a schema using their own hash
- Allow Ollama vectorizer

## [0.8.5] - 2023-07-19
- Add multi-tenancy support

## [0.8.4] - 2023-06-30
- Adding yard

## [0.8.3] - 2023-06-25
- Add Google PaLM support

## [0.8.2] - 2023-05-18

## [0.8.1] - 2023-05-10

## [0.8.0] - 2023-04-18

### Breaking
- Initializing the weaviate client requires the single `url:` key instead of separate `host:` and `schema:`

## [0.1.0] - 2023-03-24

- Initial release
