# Fixed seed keeps Faker/rand output identical run-to-run, so find_or_create_by!
# below matches existing rows instead of generating fresh duplicates each time.
srand(20_260_906)
Faker::Config.random = Random.new(20_260_906)

# Roles
admin_role = Role.find_or_create_by!(name: "admin")
moderator_role = Role.find_or_create_by!(name: "moderator")
member_role = Role.find_or_create_by!(name: "member")

# Users
# Admins and moderators always have member permissions without requiring a member role assignment.
admin_user = User.find_or_create_by!(email: "admin@communitybookshelf.org") { |u| u.password = User::DEFAULT_PASSWORD }
admin_user.roles = [admin_role, moderator_role]

mod_user = User.find_or_create_by!(email: "moderator@communitybookshelf.org") { |u| u.password = User::DEFAULT_PASSWORD }
mod_user.roles = [moderator_role]

num_members = 100
members = num_members.times.map do |i|
  full_name = Faker::Name.name
  # Index suffix guarantees email uniqueness regardless of Faker name collisions.
  email = "#{Faker::Internet.username(specifier: full_name).gsub(/[^a-z0-9.]/i, "")}.#{i}@example.com".downcase
  user = User.find_or_create_by!(email: email) { |u| u.password = User::DEFAULT_PASSWORD }
  user.roles = [member_role]
  user
end

all_users = [admin_user, mod_user] + members

# Books
# A hardcoded list of real, recognizable titles reads better in a dev seed than
# Faker's small (~190-title) pool alone, so it's used as the base and topped up with Faker.
classic_books = [
  {title: "The Great Gatsby", author: "F. Scott Fitzgerald", cover_url: "https://covers.openlibrary.org/b/id/10590366-M.jpg"},
  {title: "To Kill a Mockingbird", author: "Harper Lee", cover_url: "https://covers.openlibrary.org/b/id/14351077-M.jpg"},
  {title: "1984", author: "George Orwell", cover_url: "https://covers.openlibrary.org/b/id/9267242-M.jpg"},
  {title: "Pride and Prejudice", author: "Jane Austen", cover_url: "https://covers.openlibrary.org/b/id/14348537-M.jpg"},
  {title: "The Catcher in the Rye", author: "J.D. Salinger"},
  {title: "Brave New World", author: "Aldous Huxley"},
  {title: "The Road", author: "Cormac McCarthy"},
  {title: "Moby-Dick", author: "Herman Melville"},
  {title: "War and Peace", author: "Leo Tolstoy"},
  {title: "Crime and Punishment", author: "Fyodor Dostoevsky"},
  {title: "The Brothers Karamazov", author: "Fyodor Dostoevsky"},
  {title: "Anna Karenina", author: "Leo Tolstoy"},
  {title: "Jane Eyre", author: "Charlotte Bronte"},
  {title: "Wuthering Heights", author: "Emily Bronte"},
  {title: "Frankenstein", author: "Mary Shelley"},
  {title: "Dracula", author: "Bram Stoker"},
  {title: "The Picture of Dorian Gray", author: "Oscar Wilde"},
  {title: "Great Expectations", author: "Charles Dickens"},
  {title: "A Tale of Two Cities", author: "Charles Dickens"},
  {title: "Oliver Twist", author: "Charles Dickens"},
  {title: "David Copperfield", author: "Charles Dickens"},
  {title: "Little Women", author: "Louisa May Alcott"},
  {title: "The Adventures of Huckleberry Finn", author: "Mark Twain"},
  {title: "The Adventures of Tom Sawyer", author: "Mark Twain"},
  {title: "Of Mice and Men", author: "John Steinbeck"},
  {title: "The Grapes of Wrath", author: "John Steinbeck"},
  {title: "East of Eden", author: "John Steinbeck"},
  {title: "Slaughterhouse-Five", author: "Kurt Vonnegut"},
  {title: "Catch-22", author: "Joseph Heller"},
  {title: "The Sun Also Rises", author: "Ernest Hemingway"},
  {title: "A Farewell to Arms", author: "Ernest Hemingway"},
  {title: "For Whom the Bell Tolls", author: "Ernest Hemingway"},
  {title: "The Old Man and the Sea", author: "Ernest Hemingway"},
  {title: "Lord of the Flies", author: "William Golding"},
  {title: "Animal Farm", author: "George Orwell"},
  {title: "Fahrenheit 451", author: "Ray Bradbury"},
  {title: "The Martian Chronicles", author: "Ray Bradbury"},
  {title: "Dune", author: "Frank Herbert"},
  {title: "Foundation", author: "Isaac Asimov"},
  {title: "I, Robot", author: "Isaac Asimov"},
  {title: "The Hitchhiker's Guide to the Galaxy", author: "Douglas Adams"},
  {title: "Neuromancer", author: "William Gibson"},
  {title: "Snow Crash", author: "Neal Stephenson"},
  {title: "The Left Hand of Darkness", author: "Ursula K. Le Guin"},
  {title: "A Wizard of Earthsea", author: "Ursula K. Le Guin"},
  {title: "The Hobbit", author: "J.R.R. Tolkien"},
  {title: "The Fellowship of the Ring", author: "J.R.R. Tolkien"},
  {title: "The Two Towers", author: "J.R.R. Tolkien"},
  {title: "The Return of the King", author: "J.R.R. Tolkien"},
  {title: "The Lion, the Witch and the Wardrobe", author: "C.S. Lewis"},
  {title: "Harry Potter and the Philosopher's Stone", author: "J.K. Rowling"},
  {title: "Harry Potter and the Chamber of Secrets", author: "J.K. Rowling"},
  {title: "Harry Potter and the Prisoner of Azkaban", author: "J.K. Rowling"},
  {title: "A Game of Thrones", author: "George R.R. Martin"},
  {title: "A Clash of Kings", author: "George R.R. Martin"},
  {title: "The Name of the Wind", author: "Patrick Rothfuss"},
  {title: "Mistborn: The Final Empire", author: "Brandon Sanderson"},
  {title: "The Way of Kings", author: "Brandon Sanderson"},
  {title: "Good Omens", author: "Terry Pratchett and Neil Gaiman"},
  {title: "American Gods", author: "Neil Gaiman"},
  {title: "Coraline", author: "Neil Gaiman"},
  {title: "The Handmaid's Tale", author: "Margaret Atwood"},
  {title: "Oryx and Crake", author: "Margaret Atwood"},
  {title: "Beloved", author: "Toni Morrison"},
  {title: "Song of Solomon", author: "Toni Morrison"},
  {title: "The Color Purple", author: "Alice Walker"},
  {title: "One Hundred Years of Solitude", author: "Gabriel Garcia Marquez"},
  {title: "Love in the Time of Cholera", author: "Gabriel Garcia Marquez"},
  {title: "The Alchemist", author: "Paulo Coelho"},
  {title: "Life of Pi", author: "Yann Martel"},
  {title: "The Kite Runner", author: "Khaled Hosseini"},
  {title: "A Thousand Splendid Suns", author: "Khaled Hosseini"},
  {title: "The Book Thief", author: "Markus Zusak"},
  {title: "All the Light We Cannot See", author: "Anthony Doerr"},
  {title: "The Curious Incident of the Dog in the Night-Time", author: "Mark Haddon"},
  {title: "Never Let Me Go", author: "Kazuo Ishiguro"},
  {title: "The Remains of the Day", author: "Kazuo Ishiguro"},
  {title: "Eva Luna", author: "Isabel Allende"},
  {title: "The House of the Spirits", author: "Isabel Allende"},
  {title: "Middlemarch", author: "George Eliot"},
  {title: "Vanity Fair", author: "William Makepeace Thackeray"},
  {title: "Don Quixote", author: "Miguel de Cervantes"},
  {title: "The Count of Monte Cristo", author: "Alexandre Dumas"},
  {title: "The Three Musketeers", author: "Alexandre Dumas"},
  {title: "Les Miserables", author: "Victor Hugo"},
  {title: "The Hunchback of Notre-Dame", author: "Victor Hugo"},
  {title: "Rebecca", author: "Daphne du Maurier"},
  {title: "My Cousin Rachel", author: "Daphne du Maurier"},
  {title: "Gone with the Wind", author: "Margaret Mitchell"},
  {title: "Pavilion of Women", author: "Pearl S. Buck"},
  {title: "The Good Earth", author: "Pearl S. Buck"},
  {title: "The Kitchen God's Wife", author: "Amy Tan"},
  {title: "The Joy Luck Club", author: "Amy Tan"},
  {title: "Cry, the Beloved Country", author: "Alan Paton"},
  {title: "Things Fall Apart", author: "Chinua Achebe"},
  {title: "Half of a Yellow Sun", author: "Chimamanda Ngozi Adichie"},
  {title: "Americanah", author: "Chimamanda Ngozi Adichie"},
  {title: "Purple Hibiscus", author: "Chimamanda Ngozi Adichie"},
  {title: "The Bell Jar", author: "Sylvia Plath"},
  {title: "On the Road", author: "Jack Kerouac"},
  {title: "The Sound and the Fury", author: "William Faulkner"},
  {title: "As I Lay Dying", author: "William Faulkner"},
  {title: "Invisible Man", author: "Ralph Ellison"},
  {title: "Native Son", author: "Richard Wright"},
  {title: "The Outsiders", author: "S.E. Hinton"},
  {title: "A Clockwork Orange", author: "Anthony Burgess"},
  {title: "Trainspotting", author: "Irvine Welsh"},
  {title: "High Fidelity", author: "Nick Hornby"},
  {title: "Norwegian Wood", author: "Haruki Murakami"},
  {title: "Kafka on the Shore", author: "Haruki Murakami"},
  {title: "1Q84", author: "Haruki Murakami"},
  {title: "The Wind-Up Bird Chronicle", author: "Haruki Murakami"},
  {title: "Convenience Store Woman", author: "Sayaka Murata"},
  {title: "Klara and the Sun", author: "Kazuo Ishiguro"},
  {title: "Where the Crawdads Sing", author: "Delia Owens"},
  {title: "The Nightingale", author: "Kristin Hannah"},
  {title: "All the Bright Places", author: "Jennifer Niven"},
  {title: "The Fault in Our Stars", author: "John Green"},
  {title: "Looking for Alaska", author: "John Green"},
  {title: "Eleanor Oliphant Is Completely Fine", author: "Gail Honeyman"},
  {title: "Circe", author: "Madeline Miller"},
  {title: "The Song of Achilles", author: "Madeline Miller"},
  {title: "Educated", author: "Tara Westover"},
  {title: "Becoming", author: "Michelle Obama"},
  {title: "Sapiens", author: "Yuval Noah Harari"},
  {title: "Homo Deus", author: "Yuval Noah Harari"},
  {title: "Thinking, Fast and Slow", author: "Daniel Kahneman"},
  {title: "Outliers", author: "Malcolm Gladwell"},
  {title: "The Tipping Point", author: "Malcolm Gladwell"},
  {title: "Atomic Habits", author: "James Clear"},
  {title: "Gone Girl", author: "Gillian Flynn"},
  {title: "Sharp Objects", author: "Gillian Flynn"},
  {title: "The Girl with the Dragon Tattoo", author: "Stieg Larsson"},
  {title: "The Girl Who Played with Fire", author: "Stieg Larsson"},
  {title: "In Cold Blood", author: "Truman Capote"},
  {title: "Breakfast at Tiffany's", author: "Truman Capote"},
  {title: "The Silence of the Lambs", author: "Thomas Harris"},
  {title: "It", author: "Stephen King"},
  {title: "The Shining", author: "Stephen King"},
  {title: "Misery", author: "Stephen King"},
  {title: "Carrie", author: "Stephen King"},
  {title: "11/22/63", author: "Stephen King"},
  {title: "The Stand", author: "Stephen King"},
  {title: "Rebecca of Sunnybrook Farm", author: "Kate Douglas Wiggin"},
  {title: "Anne of Green Gables", author: "L.M. Montgomery"},
  {title: "The Secret Garden", author: "Frances Hodgson Burnett"},
  {title: "A Little Princess", author: "Frances Hodgson Burnett"},
  {title: "Charlotte's Web", author: "E.B. White"},
  {title: "Matilda", author: "Roald Dahl"},
  {title: "James and the Giant Peach", author: "Roald Dahl"},
  {title: "Charlie and the Chocolate Factory", author: "Roald Dahl"},
  {title: "The BFG", author: "Roald Dahl"},
  {title: "Where the Wild Things Are", author: "Maurice Sendak"},
  {title: "The Giving Tree", author: "Shel Silverstein"},
  {title: "Bridge to Terabithia", author: "Katherine Paterson"},
  {title: "Holes", author: "Louis Sachar"},
  {title: "Wonder", author: "R.J. Palacio"},
  {title: "The Giver", author: "Lois Lowry"},
  {title: "Hatchet", author: "Gary Paulsen"},
  {title: "Percy Jackson and the Lightning Thief", author: "Rick Riordan"},
  {title: "The Hunger Games", author: "Suzanne Collins"},
  {title: "Catching Fire", author: "Suzanne Collins"},
  {title: "Mockingjay", author: "Suzanne Collins"},
  {title: "Divergent", author: "Veronica Roth"},
  {title: "The Maze Runner", author: "James Dashner"},
  {title: "Twilight", author: "Stephenie Meyer"},
  {title: "Hollow City", author: "Ransom Riggs"},
  {title: "Miss Peregrine's Home for Peculiar Children", author: "Ransom Riggs"},
  {title: "Ready Player One", author: "Ernest Cline"},
  {title: "The Martian", author: "Andy Weir"},
  {title: "Project Hail Mary", author: "Andy Weir"},
  {title: "Station Eleven", author: "Emily St. John Mandel"},
  {title: "Love Medicine", author: "Louise Erdrich"},
  {title: "The Round House", author: "Louise Erdrich"},
  {title: "There There", author: "Tommy Orange"},
  {title: "The Overstory", author: "Richard Powers"},
  {title: "A Little Life", author: "Hanya Yanagihara"},
  {title: "The Goldfinch", author: "Donna Tartt"},
  {title: "The Secret History", author: "Donna Tartt"},
  {title: "White Teeth", author: "Zadie Smith"},
  {title: "On Beauty", author: "Zadie Smith"},
  {title: "Middlesex", author: "Jeffrey Eugenides"},
  {title: "The Virgin Suicides", author: "Jeffrey Eugenides"},
  {title: "Freedom", author: "Jonathan Franzen"},
  {title: "The Corrections", author: "Jonathan Franzen"},
  {title: "Infinite Jest", author: "David Foster Wallace"},
  {title: "A Visit from the Goon Squad", author: "Jennifer Egan"},
  {title: "The Underground Railroad", author: "Colson Whitehead"},
  {title: "The Nickel Boys", author: "Colson Whitehead"},
  {title: "The Bean Trees", author: "Barbara Kingsolver"},
  {title: "The Poisonwood Bible", author: "Barbara Kingsolver"},
  {title: "Demon Copperhead", author: "Barbara Kingsolver"},
  {title: "The Vanishing Half", author: "Brit Bennett"},
  {title: "Homegoing", author: "Yaa Gyasi"},
  {title: "The Water Dancer", author: "Ta-Nehisi Coates"},
  {title: "Between the World and Me", author: "Ta-Nehisi Coates"}
].uniq { |b| b[:title] }

target_book_count = 320
used_titles = classic_books.pluck(:title).to_set
book_pool = classic_books.dup

while book_pool.size < target_book_count
  title = Faker::Book.title
  next if used_titles.include?(title)

  used_titles << title
  book_pool << {title: title, author: Faker::Name.name}
end

books = book_pool.each_with_index.map do |book, i|
  b = Book.find_or_create_by!(title: book[:title]) do |record|
    record.author = book[:author]
    record.added_by = all_users[i % all_users.size]
  end
  b.update!(cover_url: book[:cover_url]) if book[:cover_url] && b.cover_url.blank?
  b
end

# Readings
# Reading has no callbacks to preserve, so wiping and bulk-inserting the full
# derived set (rather than 30k+ find_or_create_by! calls) keeps re-seeding idempotent and fast.
Reading.with_deleted.delete_all

status_weights = {want_to_read: 35, reading: 20, finished: 45}
weighted_statuses = status_weights.flat_map { |status, weight| [status] * weight }

# Fixed (not Time.current) so created_at/updated_at/deleted_at stay identical run-to-run.
now = Time.zone.local(2026, 9, 6)
reading_rows = []

books.each do |book|
  all_users.each do |user|
    next if rand < 0.4 # not every user reads every book

    status = weighted_statuses.sample
    created_at = now - rand(1..730).days
    # insert_all requires every hash to share the same keys, so unused columns stay nil rather than absent.
    row = {
      user_id: user.id,
      book_id: book.id,
      status: Reading.statuses[status],
      rating: nil,
      review: nil,
      deleted_at: nil,
      created_at: created_at,
      updated_at: created_at
    }

    if status == :finished
      row[:rating] = (1..5).to_a.sample
      row[:review] = Faker::Lorem.paragraph(sentence_count: rand(1..3)) if rand < 0.7
    elsif status == :reading
      row[:review] = Faker::Lorem.sentence(word_count: rand(6..14)) if rand < 0.2
    end

    row[:deleted_at] = created_at + rand(1..30).days if rand < 0.03

    reading_rows << row
  end
end

# insert_all through the default-scoped relation merges the default scope's
# where(deleted_at: nil) into every row, silently clobbering our values — use with_deleted.
reading_rows.each_slice(1000) { |slice| Reading.with_deleted.insert_all(slice) }
