using EfMigrationFixture;
using Microsoft.EntityFrameworkCore;

var command = args.SingleOrDefault();
var factory = new FixtureDbContextFactory();
await using var database = factory.CreateDbContext([]);

if (command == "--seed" &&
    Environment.GetEnvironmentVariable("EF_MIGRATION_FIXTURE_SEED_FAIL") == "1")
{
    Console.Error.WriteLine("Requested fixture seed failure.");
    return 9;
}

switch (command)
{
    case "--seed":
        await database.Database.MigrateAsync();
        await database.Widgets.ExecuteDeleteAsync();
        database.Widgets.Add(new Widget { Name = "repeatable-seed" });
        await database.SaveChangesAsync();
        Console.WriteLine("Seed completed.");
        break;

    case "--seed-count":
        Console.WriteLine(await database.Widgets.CountAsync());
        break;

    case "--create-conflict":
        await database.Database.OpenConnectionAsync();
        await database.Database.ExecuteSqlRawAsync(
            """
            CREATE TABLE "Widgets" (
                "Id" INTEGER NOT NULL CONSTRAINT "PK_Widgets" PRIMARY KEY AUTOINCREMENT,
                "Name" TEXT NOT NULL
            );
            """);
        Console.WriteLine("Conflict schema created.");
        break;

    case null:
        Console.WriteLine("Use --seed, --seed-count, or --create-conflict.");
        break;

    default:
        Console.Error.WriteLine("Unknown fixture command.");
        return 2;
}

return 0;
