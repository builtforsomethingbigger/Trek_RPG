class Adventurer < ActiveRecord::Base
    has_many :enemies
    belongs_to :user
    belongs_to :item
    @@prompt = TTY::Prompt.new

    def fight_or_town
        first_action = @@prompt.select("Where would you like to go?", ["Explore", "Town"], active_color: :red)
        yes_or_no = are_you_sure

        case first_action
        when "Explore"
            if yes_or_no == "Yes"
                nil
            else
                fight_or_town
            end
        when "Town"
            # shop_music
            if yes_or_no == "Yes"
                center_format("Ye comes across a small town wit a single shoppe.")
                shop_front_animation
                sleep(3)
                self.go_to_shop(self.current_level)
                # stop_music
                reverse_shop_animation
                system("clear")
                # exploration_music
            end
        end
    end

    def are_you_sure
        puts ""
        response = @@prompt.select("Are you sure?", ["Yes", "No"], active_color: :red)
    end

    ## THE SHOP ========================================================
    def go_to_shop(level)
        system("clear")
        item_ids = array_of_items(level).flatten
        item_1 = item_1(level, item_ids)
        item_2 = item_2(level, item_ids)
        item_3 = item_3(level, item_ids)
        item_4 = item_4(level, item_ids)
        item_5 = item_5(level, item_ids)
        item_6 = item_6(level, item_ids)

        go_to_next = false
        until go_to_next == true
            full_item_menu_choice = shop_item_menu(item_1, item_2, item_3, item_4, item_5, item_6)
            go_to_next = buying_items(full_item_menu_choice, item_1, item_2, item_3, item_4, item_5, item_6)
        end
    end

    # change the variable type.
    def get_two_items_from(item_class)
        array = []
        id_array = (0..(item_class.count-1)).to_a
        first_id = id_array.sample
        id_array.delete(first_id)
        second_id = id_array.sample

        array << item_class[first_id].id
        array << item_class[second_id].id
        array
    end

    def array_of_items(level)
        items = []
        items << get_two_items_from(armor_per_level(level))
        items << get_two_items_from(shield_per_level(level))
        items << get_two_items_from(weapons_per_level(level))
        items
    end

    def item_per_level(level)
        Item.all.select{|item| item.item_level == level}
    end

    def weapons_per_level(level)
        item_per_level(level).select{|item| item.item_type == "Weapon"}
    end

    def shield_per_level(level)
        item_per_level(level).select{|item| item.item_type == "Shield"}
    end

    def armor_per_level(level)
        item_per_level(level).select{|item| item.item_type == "Armor"}
    end

    def item_1(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[0]}
    end

    def item_2(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[1]}
    end

    def item_3(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[2]}
    end

    def item_4(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[3]}
    end

    def item_5(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[4]}
    end

    def item_6(level, item_id_array)
        item_per_level(level).find{|item| item.id == item_id_array[5]}
    end

    def shop_item_menu(one, two, three, four, five, six)
        display_stats
        item_check = @@prompt.select("Here are your items. Click for stats. (scroll for more):",
            ["#{one.name} - #{one.item_type} - $#{one.currency}",
            "#{two.name} - #{two.item_type} - $#{two.currency}",
            "#{three.name} - #{three.item_type} - $#{three.currency}",
            "#{four.name} - #{four.item_type} - $#{four.currency}",
            "#{five.name} - #{five.item_type} - $#{five.currency}",
            "#{six.name} - #{six.item_type} - $#{six.currency}",
            "Leave shoppe"], active_color: :red)
    end

    def buying_items(choice, one, two, three, four, five, six)

        case
        when choice.include?("#{one.name}")
            display_item_stats(one)
            buy_or_return(one)

        when choice.include?("#{two.name}")
            display_item_stats(two)
            buy_or_return(two)

        when choice.include?("#{three.name}")
            display_item_stats(three)
            buy_or_return(three)

        when choice.include?("#{four.name}")
            display_item_stats(four)
            buy_or_return(four)

        when choice.include?("#{five.name}")
            display_item_stats(five)
            buy_or_return(five)

        when choice.include?("#{six.name}")
            display_item_stats(six)
            buy_or_return(six)

        when "Leave shoppe"
            certainty = @@prompt.select("Are you sure? You can't come back this level.", ["leave", "stay"])
            if certainty == "leave"
                true
            else
                false
            end
        end
    end

    def buy_or_return(item)
        option = @@prompt.select("Do you want to buy this item?", ["Buy item", "Nevermind"])
        if option == "Buy item" && (self.currency - item.currency) >= 0
            buy_affordable_item(item)

        elsif option == "Buy item" && (self.currency - item.currency) < 0
          system("clear")
          fourteen_space
          puts "You cant afford this, fool!".center(112)
          fourteen_space
          sleep(2)
        end
        system("clear")
        false
    end

    def buy_affordable_item(item)
        if !self.item_id
            self.update(item_id: item.id)
        elsif !self.item_2_id
            self.update(item_2_id: item.id)
        elsif !self.item_3_id
            self.update(item_3_id: item.id)
        else
            bag_full_special_update
        end
         self.update(currency: self.currency - item.currency)
         self.update(atk: self.atk + item.atk)
         self.update(blk: self.blk + item.blk)
         self.update(hp: self.hp + item.hp)
         self.update(luck: self.luck + item.luck)
    end

    def bag_full_special_update
        item_one = Item.find(self.item_id)
        item_two = Item.find(self.item_2_id)
        item_three = Item.find(self.item_3_id)
        item_choice = @@prompt.select("Your hands are full, fool! Select an item to drop.",
        ["#{item_one.name}", "#{item_two.name}", "#{item_three.name}", "Nevermind"])

        case
        when "#{item_one.name}"
            update_stats_when_bag_full(item_one)
            self.update(item_id: item.id)

        when "#{item_two.name}"
            update_stats_when_bag_full(item_two)
            self.update(item_2_id: item.id)

        when "#{item_three.name}"
            update_stats_when_bag_full(item_three)
            self.update(item_3_id: item.id)
        end
    end

    def update_stats_when_bag_full(item)
        self.update(atk: self.atk - item.atk)
        self.update(blk: self.blk - item.blk)
        self.update(hp: self.hp - item.hp)
        self.update(luck: self.luck - item.luck)
    end

    ## API Requests ================================================
    def get_movie_and_news
        choice =  @@prompt.select("You're tired. Take a break and heal?", ["Sounds awesome.", "No I'm feeling snappy."])
        if choice == "Sounds awesome."
            movie_or_news = @@prompt.select("Watch a movie or read the news?", ["Watch Movie / TV", "Read News", "Ready to rock."])
            perusal_choice(movie_or_news)

            self.update(atk: self.atk + 1, blk: self.blk + 1, hp: self.hp + 5)
            six_space
            puts "Your stats regenerated slightly...".center(112)
            display_stats
        end
    end

    def perusal_choice(movie_or_news)
        if movie_or_news == "Watch Movie / TV"
            movie_loop
        elsif movie_or_news == "Read News"
            news_loop
        end
    end

    def movie_loop
        loop do
            six_space
            system("clear")
            movie = @@prompt.ask("Search movie / show:")
            puts ""
            Getdata.get_movie(movie)
            puts ""
            puts ""
            watch = @@prompt.select("Is that the one?", ["Yes, thanks Jarvis.", "No, search another movie."])
            if watch == "Yes, thanks Jarvis."
                break
            end
        end
    end

    def news_loop
        loop do
            six_space
            article_type = @@prompt.select("Scroll publication or headlines:", ["Publication", "US Headlines", "Business Headlines", "Tech News", "Feeling refreshed"])
            if article_type == "Feeling refreshed"
                break
            else
                Getdata.get_article_by(article_type)
            end
        end
    end

    ## BATTLES =====================================================
    def create_enemy
        new_enemy = Enemy.create(boss?: false, atk: [2, 3].sample, blk: [4, 5, 6].sample, hp: [12, 13, 14, 15].sample, currency: [13, 14, 15, 16].sample, item_id: rand(1..16))
        new_enemy.update(name: Getdata.get_character)
        item = Item.find(new_enemy.item_id)
        new_enemy.update(atk: (new_enemy.atk + item.atk), blk: (new_enemy.blk + item.blk), hp: (new_enemy.hp + item.hp))
        self.enemies << new_enemy
        new_enemy
    end

    def create_boss
        new_boss = Enemy.create(boss?: true, atk: [10, 11, 12, 13].sample, blk: [12, 13, 14, 15].sample, hp: [12, 13, 14, 15].sample, currency: 100)
        new_boss.update(name: Getdata.get_character)
        new_boss
    end

    def game_loop(opponent, enemy_number)
        keep_playing = true
        until keep_playing == false
            system("clear")
            enemy_icons[enemy_number].call
            display_hp
            opponent.move_prompt
            opponent.attack(self)
            sleep(1)
            keep_playing = opponent.check_for_victor(self, enemy_number)
            if keep_playing == true
                opponent.defend(self)
                sleep(1)
                keep_playing = opponent.check_for_victor(self, enemy_number)
            end
        end
    end

    def encounter_boss
        fourteen_space
        feast = prompt.select("Would you like to join our feast today?", ["Yes", "No"])
        if feast == "Yes"
            center_format("Wonderful! Right this way! Fooollllooowww meeee!! wiiippeeee!!!")
        else
            center_format("Oh no no, I insist, Please! follow me, you'll love the feast!")
        end
        sleep(1)
        system("clear")
        boss = self.create_boss
        center_format("King #{boss.name} look!!!
                   ......I BROUGHT YOUR FEAST!")
        sleep(1)
        boss
    end

    ## STATS ======================================================
    def beginning_stats
        system("clear")
        display_adventurer_ascii(self.class_type)
        sleep(1)
        system("clear")
        six_space
        puts "You chose #{self.class_type}!".center(112)
        puts "~~~~~~~~~~~~".center(112)
        six_space

        adventurer_name = @@prompt.ask("What is your adventurer's name?", active_color: :red)
        self.update(name: adventurer_name)
        system("clear")
        six_space
        puts "#{self.name}'s stats:".center(112)
        display_stats
        sleep(6)
        system("clear")
    end
    def display_stats
        puts ""
        puts "Sheckles: $#{self.currency}".center(112)
        puts ""
        puts ""
        display_fight_stats
        puts ""
    end
    def display_fight_stats
        puts "Attack: #{self.atk}".center(112)
        puts "~~~~~~~~~~~~".center(112)
        puts "Block: #{self.blk}".center(112)
        puts "~~~~~~~~~~~~".center(112)
        puts "Health: #{self.hp}".center(112)
        puts "~~~~~~~~~~~~".center(112)
        puts "Luck: #{self.luck}".center(112)
        puts ""
    end

    def your_stats_with_item(item)
        puts "Attack: #{self.atk + item.atk}".center(112)
        puts "Block: #{self.blk + item.blk}".center(112)
        puts "Health: #{self.hp + item.hp}".center(112)
        puts "Luck: #{self.luck + item.luck}".center(112)
    end

    def display_item_stats(item)
        system("clear")
        six_space
        puts "Sheckles: $#{self.currency}".center(112)
        puts ""
        puts "Updated stats with item".center(112)
        your_stats_with_item(item)
        puts ""
        puts ""
        puts "Item: #{item.name.upcase}"
        puts "Cost: #{item.currency}"
        puts ""
        puts "Attack: #{item.atk}"
        puts "Block: #{item.blk}"
        puts "Health: #{item.hp}"
        puts "Luck: #{item.luck}"
        puts ""
    end

    def display_hp
        puts "Block remaining: #{self.blk}"
        puts "HP remaining: #{self.hp}"
        puts ""
    end

    def save_block
        @saved_block = []
        @saved_block << self.blk
    end

    def return_block_to_original
        self.update(blk: @saved_block[0])
    end

    ## MISCELLANEOUS ================================================
    def encounter_castle
        system("clear")
        center_format("A castle morphs into the field of view!
                 What kind of sorcery is this!?")
        castle_materializes
        center_format("something emerges from the front gate... wait...
                   is that a..?")
        kangaroo
        center_format("Hello weary traveller!
           Welcome to Bearington!!")

        center_format("It's your lucky day...
                   today the king is back from his travels and we are having a feast!!")
        system("clear")
    end

    def display_adventurer_ascii(class_type)
        case class_type
        when "Juggernaut"
            juggernaut_ascii
        when "Street Rat"
            street_rat_ascii
        when "Warrior"
            warrior_ascii
        when "Tax Collector"
            tax_collector_ascii
        when "Con Artist"
            con_artist_ascii
        end
    end

    def exploring
        system("clear")
        framed_narration("Wait... it appears #{self.name} has gotten lost...
                         Wandering aimlessly around this desolate plain...")
        sleep(3)
        system("clear")
        tree_animation
        system("clear")
        framed_narration(" 'Is there anyone out there?' ")
        sleep(2)
        system("clear")
        reverse_tree_animation
        system("clear")
        framed_narration("      '....It feels like im just going in circles' ")
        sleep(2)
        system("clear")
    end

    def to_be_continued
        center_format("Coming soon...")
        sleep(4)
        center_format("to CLI near you...")
        sleep(2.5)
        system("clear")
        level_two_logo
        sleep(3)
        system("clear")
        six_space
        cya_next_time
        sleep(20)
        exit
    end

    def framed_narration(sentence)
        puts "=============================================================================================================="
        six_space
        puts ""
        puts ""
        puts sentence.center(112)
        six_space
        six_space
        puts "=============================================================================================================="
    end

    def center_format(sentence)
        system("clear")
        fourteen_space
        puts sentence.center(112)
        sleep(2)
    end

    def self.game_over_main_menu
        @@prompt.select("Exit game:", ["Exit"])
        exit
    end

    def fourteen_space
        six_space
        six_space
        puts ""
        puts ""
    end

    def six_space
        puts ""
        puts ""
        puts ""
        puts ""
        puts ""
        puts ""
    end
end
