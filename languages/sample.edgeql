# EdgeDB: schema plus a few queries against it.
module default {
    type Person {
        required name: str { constraint exclusive; }
        joined: datetime { default := datetime_current(); }
        multi projects: Project;
    }

    type Project {
        required title: str;
        budget: decimal;
        index on (.title);
    }
}

# Insert and link
insert Person {
    name := "Ada",
    projects := (insert Project { title := "Sidewatch", budget := 120000n })
};

# People on well-funded projects, with a computed count
select Person {
    name,
    project_count := count(.projects),
    big := (select .projects filter .budget > 100000n) { title }
}
filter exists .big
order by .name;
