using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;

#nullable disable

namespace EfMigrationFixture.Migrations;

[DbContext(typeof(FixtureDbContext))]
partial class FixtureDbContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
#pragma warning disable 612, 618
        modelBuilder.HasAnnotation("ProductVersion", "8.0.28");

        modelBuilder.Entity("EfMigrationFixture.Widget", entity =>
        {
            entity.Property<int>("Id")
                .ValueGeneratedOnAdd()
                .HasColumnType("INTEGER");

            entity.Property<string>("Name")
                .IsRequired()
                .HasMaxLength(100)
                .HasColumnType("TEXT");

            entity.HasKey("Id");
            entity.ToTable("Widgets");
        });
#pragma warning restore 612, 618
    }
}
