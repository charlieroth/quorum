# Voting Center Naming Convention

Currently there is no standardized naming convention for voting centers in
the United States. Having such a standardization is crucial for verifiability
of a vote. A standardization also has the benefit of creating a mapping of
a voting center to a data center. A data center would known what voting centers
it is responsible for and vice versa.

I asked ChatGPT, "If you tasked with create a naming convention for voting centers, what are some ideas you would have?

ChatGPT responded with the following:

Creating a naming convention for voting centers requires balancing uniqueness, simplicity, and information richness. Here are some approaches:

State-Precinct-Ward Format: `[StateAbbreviation]-[PrecinctNumber]-[WardNumber]`
Example: `CA-101-02`
Benefit: Geographic hierarchy and ease of mapping to location.

Hashed Identifier: Utilizing a cryptographic hash of key attributes like location, precinct, and ward.
Example: `SHA256("CA-Precinct101-Ward02")`
Benefit: Uniqueness and verifiability.

Alphanumeric Codes: A unique alphanumeric code representing each center, mapped internally to details.
Example: `ZXA9`
Benefit: Brevity and ease of data entry.

ISO Region Codes: `[ISO3166-2:State]-[Precinct]-[Ward]`
Example: `US-CA-101-02`
Benefit: International standardization.

Timestamp-based: `[State]-[Precinct]-[UnixTimestamp]`
Example: CA-101-1632409214
Benefit: Includes the time of establishment, useful for versioning or tracking changes.

Functional Descriptors: Adding a functional component that indicates the type of voting center (e.g., general, early voting, mail-in).
Example: `CA-101-02-Early`
Benefit: Provides immediate context.

Geohash: Utilizing Geohashing to generate a unique code based on the geographical coordinates of the voting center.
Example: `u4pruydqqvj`
Benefit: Implicit geographic information.

Multi-level: A multi-level approach that combines elements from above, separated by a delimiter.
Example: `CA-101-02#ZXA9`
Benefit: Detailed, yet flexible.

These conventions can be tailored further based on specific needs, such as accommodating additional administrative layers or types of voting centers.
